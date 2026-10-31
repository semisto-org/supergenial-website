require "zip"
require "nokogiri"

# Reads the cells of an .xlsx workbook (values only: no formulas, no styles), sheet by sheet.
# Enough for the plain exports of accounting tools; numbers stay numbers, dates come as serial numbers.
class XlsxReader
  EPOCH = Date.new(1899, 12, 30)

  # Excel stores dates as the number of days since its epoch.
  def self.date(value)
    case value
    when Numeric then EPOCH + value.to_i
    when String then value.strip.empty? ? nil : (Float(value, exception: false) ? EPOCH + value.to_f.to_i : Date.parse(value))
    end
  rescue Date::Error
    nil
  end

  def initialize(data)
    @data = data
  end

  # { "sheet name" => [ [ cell, cell, … ], … ] }
  def sheets
    result = {}
    Zip::File.open_buffer(StringIO.new(@data)) do |zip|
      strings = shared_strings(zip)
      sheet_paths(zip).each do |name, path|
        entry = zip.find_entry(path)
        result[name] = entry ? rows(Nokogiri::XML(entry.get_input_stream.read).remove_namespaces!, strings) : []
      end
    end
    result
  end

  private
    def shared_strings(zip)
      entry = zip.find_entry("xl/sharedStrings.xml")
      return [] unless entry
      Nokogiri::XML(entry.get_input_stream.read).remove_namespaces!.xpath("//si").map { |item| item.xpath(".//t").map(&:text).join }
    end

    # Sheet names come from the workbook, their files from its relationships.
    def sheet_paths(zip)
      workbook = Nokogiri::XML(zip.read("xl/workbook.xml"))
      relations = zip.find_entry("xl/_rels/workbook.xml.rels")&.then { |entry| Nokogiri::XML(entry.get_input_stream.read).remove_namespaces! }
      targets = relations ? relations.xpath("//Relationship").to_h { |relation| [ relation["Id"], relation["Target"] ] } : {}
      workbook.xpath("//*[local-name()='sheet']").each_with_index.map do |sheet, index|
        id = sheet.attributes.values.find { |attribute| attribute.name == "id" }&.value
        target = targets[id] || "worksheets/sheet#{index + 1}.xml"
        [ sheet["name"], target.start_with?("/") ? target.delete_prefix("/") : "xl/#{target}" ]
      end
    end

    def rows(sheet, strings)
      sheet.xpath("//sheetData/row").map do |row|
        row.xpath("c").each_with_object([]) do |cell, values|
          values[column_index(cell["r"]) || values.size] = value(cell, strings)
        end
      end
    end

    def value(cell, strings)
      case cell["t"]
      when "s" then strings[cell.at_xpath("v")&.text.to_i]
      when "inlineStr" then cell.xpath(".//t").map(&:text).join
      when "str", "e" then cell.at_xpath("v")&.text
      when "b" then cell.at_xpath("v")&.text == "1"
      else cell.at_xpath("v")&.text&.then { |text| text.include?(".") || text.include?("E") ? BigDecimal(text) : text.to_i }
      end
    end

    # "C12" → 2
    def column_index(reference)
      letters = reference.to_s[/\A[A-Z]+/]
      letters&.each_char&.reduce(0) { |index, letter| index * 26 + letter.ord - 64 }&.-(1)
    end
end
