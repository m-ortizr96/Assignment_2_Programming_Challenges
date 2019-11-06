#require './InteractionNetwork2.rb'
require './PRUEBAAA.rb'

puts "Creating output, this is going to take some time, please wait"
$network = []

InteractionNetwork2.data("ArabidopsisSubNetwork_GeneList.txt")

line=[]
file = File.open("ArabidopsisSubNetwork_GeneList.txt", "r")
file.each do |lines|
  line<< lines
end


x=line.length-1


def outputfile(filename, length)
  fo = File.open(filename, "w")
  #x= $network.length

  fo.puts "Assigment 2 - Maria Ortiz Rodriguez"
  fo.puts "=================================================================================="
  for i in 0..length do
    unless $network[i].protein_protein_interaction1.nil?
      fo.puts "Network number #{i}"
      unless $network[i].intact_id.nil?
        fo.puts "Gene ID: #{$network[i].gene_id} encodes the protein #{$network[i].protein_id} with IntActID: #{$network[i].intact_id}"
      else
        fo.puts "Gene ID: #{$network[i].gene_id} encodes the protein #{$network[i].protein_id}"
      end

      fo.puts "\n"

      fo.puts "Interaction Proteins: --- Number of nodes #{$network[i].protein_protein_interaction1.count} \n "
      $network[i].protein_protein_interaction1.each do |protein1, protein2|
         fo.puts "level 1"
        fo.puts "Protein #{protein1} interacts with #{protein2}"
        unless $network[i].protein_protein_interaction2.nil?
          fo.puts "level 2"
          $network[i].protein_protein_interaction2.each do |p1, p2|
            fo.puts "Protein #{p1} interacts with #{p2}"
          end
        end
      end
      fo.puts "\n"

      unless $network[i].go.nil?
        $network[i].go.each do |go_id, go_path|
          fo.puts "\t GO ID: #{go_id} \t GO_Path: #{go_path}"
        end
      end
      fo.puts "\n"
      unless $network[i].kegg.nil?
        $network[i].kegg.each do |kegg_id, kegg_path|
          fo.puts "\t Kegg ID: #{kegg_id} \t Kegg_Path #{kegg_path}"
        end
      end

      fo.puts "=========================================================="
    end
  end

  fo.close
end


outputfile("outputbuenoMariaOrtiz.txt", x)
