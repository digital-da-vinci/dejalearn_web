module PacketPagesHelper
	
	def self.create_xml(params, packet_id)
		require "builder"

		builder = Builder::XmlMarkup.new(:indent=>2)
		builder.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
		
		id_list = Array.new
		params.keys.each do |key|
			if key =~ /type-[0-9]+/
				id_list.push(key.scan(/[0-9]+/)[0])
			end
		end
		index = 0
		xml = builder.packet { |b| 

			id_list.each do |id|
				b.exercise { |e|
					e.number(index)
					e.type(params["type-#{id}"])
					e.question(params["question-#{id}"])
					e.answer(params["answer-#{id}"])
					e.hint(params["hint-#{id}"])

					if (params["type-#{id}"] == "MC")
						e.choices{ |c|
							c.choiceA(params["optionA-#{id}"])
							c.choiceB(params["optionB-#{id}"])
							c.choiceC(params["optionC-#{id}"])
							c.choiceD(params["optionD-#{id}"])
						}
					elsif (params["type-#{id}"] == "IMC")
						image_url = get_alt_url(Images.where("packet_id = ? AND question_id = ?", packet_id, id).first.image.url(:original))
						e.image(image_url)

						e.choices{ |c|
							c.choiceA(params["optionA-#{id}"])
							c.choiceB(params["optionB-#{id}"])
							c.choiceC(params["optionC-#{id}"])
							c.choiceD(params["optionD-#{id}"])
						}

					elsif (params["type-#{id}"] == "FIB")
					end
					index += 1

				}
			end
		}
		
		File.open("#{params[:title]}.xml", "w"){ |f| f.write(xml) }

		file = File.open("#{params[:title]}.xml")
		return file
		
	end

	def self.save_images(params, packet_id)
		id_list = Array.new
		params.keys.each do |key|
			if key =~ /type-[0-9]+/
				id_list.push(key.scan(/[0-9]+/)[0])
			end
		end

		id_list.each do |id|
			image = Images.new
			
			image.packet_id = packet_id
			image.question_id = id
			
			if params["selectImage-#{id}"] == '' or params["selectImage-#{id}"].nil?
				image.image = params["urlImage-#{id}"]
			end

			if params["urlImage-#{id}"] == ''
				image.image = params["selectImage-#{id}"]
			end
			
			image.save

		end
	end

	def self.save_tags(tag_string, packet)
		tags = tag_string.split(',')
		tags.each do |tag|
			new_tag = Tag.new(:tag => tag.downcase.strip , :used => 1)
			
			if new_tag.save
				new_tag.packets << packet
				new_tag.save
			else 
				t = Tag.where(:tag => tag).first
				t.packets.each do |pack|
					unless pack.id == packet.id
						t.packets << packet
						t.save
					end
				end
				
			end
		end
	end

	def self.get_alt_url(url)
		url = url.to_s.gsub("http://s3.amazonaws.com/dejalearn" ,"http://dejalearn.s3.amazonaws.com")
		return url
	end
end