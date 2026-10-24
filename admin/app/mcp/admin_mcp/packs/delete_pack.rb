class AdminMcp::Packs::DeletePack < AdminMcp::DeleteTool
  description "Delete a pack. Its time entries are kept and go back to the a_facturer (unbilled) status."
  model Pack
end
