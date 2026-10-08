# Compila Text_italiano_core/*.txt in Data/messages_italiano_core.dat senza
# aprire il gioco (fa la stessa cosa di Debug > Files > "Compile translated text").
#
# Uso, dalla cartella del progetto:
#   ruby --disable-gems Strumenti/compila_traduzione.rb
#
# Formato dei file .txt: dopo l'intestazione [SEZIONE], le righe vanno a coppie:
# frase originale in inglese, poi la traduzione. Gli a capo si scrivono <<n>>.
Encoding.default_external = Encoding::UTF_8

SECTIONS = { "SCRIPT_TEXTS" => 24 }.freeze
SIZE = 31

def denormalize(v)
  v.gsub("<<1>>", "\1").gsub("<<r>>", "\r").gsub("<<n>>", "\n")
   .gsub("<<[>>", "[").gsub("<<]>>", "]").gsub("<<t>>", "\t")
end

def string_to_key(s)
  return s unless s[/[\r\n\t\1]|^\s+|\s+$|\s{2,}/]
  s.sub(/^\s+/, "").sub(/\s+$/, "").gsub(/\s{2,}/, " ")
end

root = File.expand_path("..", __dir__)
all = Array.new(SIZE)
Dir[File.join(root, "Text_italiano_core", "*.txt")].sort.each do |path|
  section = nil
  pending = nil
  File.binread(path).force_encoding("UTF-8").delete_prefix("﻿").split(/\r?\n/).each do |line|
    next if line.start_with?("#") || line.strip.empty?
    if line =~ /^\[(.+)\]$/
      section = SECTIONS.fetch($1) { abort "Sezione sconosciuta: #{$1} in #{path}" }
      all[section] ||= {}
      next
    end
    abort "Testo fuori da una sezione in #{path}" unless section
    if pending.nil?
      pending = string_to_key(denormalize(line))
    else
      text = denormalize(line)
      all[section][pending] = text unless text == pending
      pending = nil
    end
  end
  abort "Numero di righe dispari in #{path}" if pending
end
File.binwrite(File.join(root, "Data", "messages_italiano_core.dat"), Marshal.dump(all))
puts "Scritto Data/messages_italiano_core.dat (#{all.compact.sum(&:size)} frasi tradotte)"
