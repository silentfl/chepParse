require 'nokogiri'
require 'open-uri'
require 'json'

URLS = {
  "Недвижимость"=> { 
  "Покупка"=> "http://www.chepetsk.ru/do/?id=realty&sid=realtybuy",
  "Продажа"=> "http://www.chepetsk.ru/do/?id=realty&sid=realtysell",
  "Обмен"=> "http://www.chepetsk.ru/do/?id=realty&sid=realtyxch",
  "Аренда жилья"=> "http://www.chepetsk.ru/do/?id=realty&sid=arenda",
  "Гаражи и сады"=> "http://www.chepetsk.ru/do/?id=realty&sid=srealty",
  "Коммерческая"=> "http://www.chepetsk.ru/do/?id=realty&sid=commerc"
},
  "Работа"=> {
  "Требуются"=> "http://www.chepetsk.ru/do/?id=job&sid=sjob",
  "Ищу работу"=> "http://www.chepetsk.ru/do/?id=job&sid=fjob"
},
  "Даром"=> {
  "Отдам"=> "http://www.chepetsk.ru/do/?id=darom&sid=otdam",
  "Приму"=> "http://www.chepetsk.ru/do/?id=darom&sid=primu"
},
  "Техника"=> {
  "Бытовая"=> "http://www.chepetsk.ru/do/?id=tech&sid=byt",
  "Аудио, видео, фото"=> "http://www.chepetsk.ru/do/?id=tech&sid=av",
  "Компьютеры"=> "http://www.chepetsk.ru/do/?id=tech&sid=comp",
  "Мобильные устройства"=> "http://www.chepetsk.ru/do/?id=tech&sid=mobil"
},
  "Все для дома"=> {
  "Все для дома"=> "http://www.chepetsk.ru/do/?id=dom"
},
  "Разное куплю"=> {
  "Разное куплю"=> "http://www.chepetsk.ru/do/?id=buy"
},
  "Автомобили"=> {
  "Запчасти"=> "http://www.chepetsk.ru/do/?id=auto&sid=autozap",
  "Иномарки"=> "http://www.chepetsk.ru/do/?id=auto&sid=inauto",
  "Отечественные"=> "http://www.chepetsk.ru/do/?id=auto&sid=rusauto"
},
  "Животные"=> {
  "Животные"=> "http://www.chepetsk.ru/do/?id=pets"
},
  "Разное продам"=> {
  "Разное продам"=> "http://www.chepetsk.ru/do/?id=other"
},
  "Находки и потери"=> {
  "Находки и потери"=> "http://www.chepetsk.ru/do/?id=nahodki"
},
  "Детское"=> {
  "Одежда и обувь"=> "http://www.chepetsk.ru/do/?id=kids&sid=oio",
  "Коляски"=> "http://www.chepetsk.ru/do/?id=kids&sid=kolyaski",
  "Питание"=> "http://www.chepetsk.ru/do/?id=kids&sid=pitanie",
  "Разное"=> "http://www.chepetsk.ru/do/?id=kids&sid=raznoe"
},
  "Услуги"=> {
  "Услуги"=> "http://www.chepetsk.ru/do/?id=uslugi"
},
  "Одежда, обувь и аксессуары"=> {
  "Одежда, обувь и аксессуары"=> "http://www.chepetsk.ru/do/?id=clothes"
}
}
class Struct
  def to_map
    map = Hash.new
    self.members.each { |m| map[m] = self[m] }
    map
  end

  def to_json(*a)
    to_map.to_json(*a)
  end
end

class Item < Struct.new(:title, :text, :phone, :has_email, :author, :image, :image_big, :date); end

def main(fout)
  puts "Start"
  messages = {}
  URLS.each do |part, values|
    p = {}
    values.each do |item, url|
      p[item] = getMessages(url) 
    end
    messages[part] = p
  end
  fout.puts JSON.pretty_generate(messages)
  fout.close
end

def getMessages(url)
  msgs = []
  doc = Nokogiri::HTML(open(url))
  list = doc.css('.ls a')
  if list.any?
    count = list[list.size-2].text.tr('.','').to_i
  else
    count = 1
  end
  puts sprintf("%s %s", count, url)
  (1..count).each do |page|
    msgs += getMsgs(url + "&page=#{page}")
  end
  msgs
end

def getMsgs(url)
  res = []
  printf("\t%s: ",url)
  doc = Nokogiri::HTML(open(url))
  begin
    doc.css(".container table table[bgcolor='#CECFCE']").each do |item|
      a = item.css('.cont')
      if a.size > 3
        msg = Item.new
        msg[:title] = item.css('.doska1').text
        msg[:text] = item.css('.txt2').text
        msg[:author] = a[0].text[7..-1]   #отрезаем в начале строки "Автор: "
        msg[:phone] = a[2].text[13..-1]   #отрезаем "Телефон: "
        msg[:has_email] = !a[2].text.strip.empty?
        msg[:date] = a[3].text[20..26]
        image = item.css('.img a img')[0]['src'] rescue nil
        if image != nil
          filename = 'upload/' + (image.hash + 2**31).to_s + File.extname(image)
          msg[:image] = filename
          msg[:image_big] = image.gsub('small','big')
          download(image, filename)
        end
        res << msg
      end
    end
  rescue Exception => e
    puts "FAIL\n#{ e.message }"
    return []
  end
  puts "OK"
  res
end

#загружает файл по урлу url, сохраняет под именем name
def download(url, name)
  begin
    IO.write(name, open(url).read)
  rescue Exception => e 
    puts "Fail download image #{url}:\n#{e.message}"
  end
end

main(File.open("out.json","w"))
#fout = File.open("out.json","w")
#msg = getMsgs("http://www.chepetsk.ru/index.php?do/&id=kids&sid=oio&page=10")
#puts msg
#fout.puts JSON.pretty_generate(msg)
#fout.close
