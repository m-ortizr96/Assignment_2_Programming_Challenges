require 'rest-client'
require 'json'


class InteractionNetwork
  attr_accessor :gene_id
  attr_accessor :protein_id
  attr_accessor :kegg
  attr_accessor :go
  attr_accessor :intact_id
  attr_accessor :protein_protein_interaction1
  attr_accessor :protein_protein_interaction2
  #attr_accessor :protein_protein_interaction3

  @@total_gene_objects = Hash.new


  def initialize (params = {})
    @gene_id = params.fetch(:gene_id, "ATXGXXX")
    @protein_id = params.fetch(:protein_id, "XXXXX")
    @kegg = params.fetch(:kegg, Hash.new)
    @go = params.fetch(:go, Hash.new)
    @intact_id = params.fetch(:intact_id, "XXXX_XXXX")
    @protein_protein_interaction1 = params.fetch(:protein_protein_interaction1, Array.new)
    @protein_protein_interaction2 = params.fetch(:protein_protein_interaction2, Array.new)

    @@total_gene_objects[gene_id] = self


  end

  def self.all_genes
    return @@total_gene_objects
  end

  def self.get_protein_id(gene_id)
    addressprot = "http://togows.org/entry/ebi-uniprot/#{gene_id}/entry_id.json" #given a gene_id from our list, we can obtain de protein_id
    response = RestClient::Request.execute(
        method: :get,
        url: addressprot)
    data_prot = JSON.parse(response.body)
    return data_prot[0]
  end



  def InteractionNetwork.data(filename) #it takes the information of the file .txt and we can get gene id, protein id, intact id, the proteins interaction level 1 and 2
    file = File.open(filename, "r")
    file.each_with_index do |line, index| ####QUITAR LO DEL INDEX
      line.delete!("\n")
      protein_id = get_protein_id(line)

      intact_id = get_intact_id(line)

      unless intact_id.nil? #sometimes the intact id doesnt exist
        protein_protein_interaction1 = get_protein_interaction1(intact_id) #first level of protein-protein interaction

        protein_protein_interaction2 = []

        protein_protein_interaction1.each do |int1, int2|
          if not int1 == intact_id
            protein_protein_interaction2 = get_protein_interaction2(int1) #second level of protein-protein interaction
          end

          if not int2 == intact_id
            protein_protein_interaction2 = get_protein_interaction2(int2)
          end
        end
        puts ""
      else
        protein_protein_interaction1 = []
      end



      go = go(line)
      kegg = kegg(line)

      $network[index] = InteractionNetwork.new(
          :gene_id =>line,
          :protein_id => protein_id,
          :intact_id => intact_id,
          :protein_protein_interaction1 => protein_protein_interaction1,
          :protein_protein_interaction2 => protein_protein_interaction2,
          :go => go,
          :kegg => kegg
      )

    end
    file.close
  end

  def self.get_intact_id(gene_id)
    address = "http://togows.org/entry/ebi-uniprot/#{gene_id}/dr.json"
    response = RestClient::Request.execute(
        method: :get,
        url: address)

    data = JSON.parse(response.body)

    unless data[0]["IntAct"].nil?
      return data[0]["IntAct"][0][0]
    end
  end

  def self.get_protein_interaction1(intactid)

    #level 1
    addressinteraction = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{intactid}?format=tab27"
    responseinteraction = RestClient::Request.execute(
        method: :get,
        url: addressinteraction)

    datainteraction = responseinteraction.body

    ppis = Array.new

    lines = datainteraction.split("\n")

    lines.each do |lanee|
      fields = lanee.split("\t")


      interaction = /uniprotkb:/
      if (fields[0] =~ interaction) && (fields[1] =~ interaction)
        protein1 = fields[0].sub(interaction ,"")
        protein2 = fields[1].sub(interaction,"")

        filter_interaction_arath = /taxid:3702/ #https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=3702 information about Taxon ID of arath

        case
        when protein1 == protein2
          next
        when ((fields[9] =~ filter_interaction_arath) && (fields[10] =~ filter_interaction_arath))
          # puts "#{protein1} this is 1"
          #puts "#{protein2} this is 2"
          if protein1 < protein2
            if not @@total_gene_objects.include?([protein1, protein2])
              #   @@total_gene_objects << [protein1, protein2]
              ppis << [protein1, protein2]
            end
          else
            if not @@total_gene_objects.include?([protein2,protein1])
              # @@total_gene_objects  [protein2, protein1]
              ppis << [protein2, protein1]
            end
          end


        else
          next
        end



      end

    end


    return ppis.sort! #we sort the list of protein - protein interaction

  end

  def self.get_protein_interaction2(intactid) #same code as before but for level 2

    #level 1
    addressinteraction = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{intactid}?format=tab27"
    responseinteraction = RestClient::Request.execute(
        method: :get,
        url: addressinteraction)

    datainteraction = responseinteraction.body

    ppis = Array.new

    lines = datainteraction.split("\n")

    lines.each do |lanee|
      fields = lanee.split("\t")


      interaction = /uniprotkb:/
      if (fields[0] =~ interaction) && (fields[1] =~ interaction)
        protein1 = fields[0].sub(interaction ,"")
        protein2 = fields[1].sub(interaction,"")

        filter_interaction_arath = /taxid:3702/ #https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=3702 information about Taxon ID of arath

        case
        when protein1 == protein2
          next
        when ((fields[9] =~ filter_interaction_arath) && (fields[10] =~ filter_interaction_arath))
          # puts "#{protein1} this is 1"
          #puts "#{protein2} this is 2"
          if protein1 < protein2
            if not @@total_gene_objects.include?([protein1, protein2])
              #   @@total_gene_objects << [protein1, protein2]
              ppis << [protein1, protein2]
            end
          else
            if not @@total_gene_objects.include?([protein2,protein1])
              # @@total_gene_objects  [protein2, protein1]
              ppis << [protein2, protein1]
            end
          end

          # ppis.uniq #####MIRAR!

        else
          next
        end



      end


    end

    return ppis.sort!

  end

  def self.go(gene_id)
    go = Hash.new
    addressgo = "http://togows.org/entry/ebi-uniprot/#{gene_id}/dr.json"
    #addressgo = "http://togows.dbcls.jp/entry/uniprot/#{self.protein_id}/dr.json"
    responsego = RestClient::Request.execute(
        method: :get,
        url: addressgo)

    datago = JSON.parse(responsego.body)
    unless datago[0]["GO"].nil?
      datago[0]["GO"].each do |num|
        if num[1] =~ /^P:/
          go[num[0]] = num[1].sub(/P:/,"")
        end
      end
    end
    return go
  end

  def self.kegg(gene_id)
    kegg = Hash.new
    addresskegg = "http://togows.org/entry/kegg-genes/ath:#{gene_id}/pathways.json"
    response = RestClient::Request.execute(
        method: :get,
        url: addresskegg)
    datakegg= JSON.parse(response.body)

    unless datakegg[0].nil?
      datakegg[0].each do |keggid, kegpath|
        kegg[keggid] = kegpath
        # puts self.kegg
      end
      return kegg
    end

  end

end

