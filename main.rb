#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'json'
require 'parallel'

URLS = {
  "Недвижимость" => {
    "Квартиры" => "http://www.chepetsk.ru/do/?id=realty&sid=realtysell",
    "Аренда жилья" => "http://www.chepetsk.ru/do/?id=realty&sid=arenda",
    "Дома, сады, земля" => "http://www.chepetsk.ru/do/?id=realty&sid=doma",
    "Гаражи" => "http://www.chepetsk.ru/do/?id=realty&sid=srealty",
    "Покупка" => "http://www.chepetsk.ru/do/?id=realty&sid=realtybuy",
    "Обмен" => "http://www.chepetsk.ru/do/?id=realty&sid=realtyxch",
    "Коммерческая" => "http://www.chepetsk.ru/do/?id=realty&sid=commerc"
  },
  "Работа" => {
    "Требуются" => "http://www.chepetsk.ru/do/?id=job&sid=sjob",
    "Ищу работу" => "http://www.chepetsk.ru/do/?id=job&sid=fjob"
  },
  "Даром" => {
    "Отдам" => "http://www.chepetsk.ru/do/?id=darom&sid=otdam",
    "Приму" => "http://www.chepetsk.ru/do/?id=darom&sid=primu"
  },
  "Техника" => {
    "Бытовая" => "http://www.chepetsk.ru/do/?id=tech&sid=byt",
    "Аудио, видео, фото" => "http://www.chepetsk.ru/do/?id=tech&sid=av",
    "Компьютеры" => "http://www.chepetsk.ru/do/?id=tech&sid=comp",
    "Мобильные устройства" => "http://www.chepetsk.ru/do/?id=tech&sid=mobil",
    "Инструмент" => "http://www.chepetsk.ru/do/?id=tech&sid=instr"
  },
  "Мебель и все для дома" => {
    "Мебель и все для дома" => "http://www.chepetsk.ru/do/?id=dom"
  },
  "Разное куплю" => { "Разное куплю" => "http://www.chepetsk.ru/do/?id=buy"
  },
  "Автомобили" => {
    "Иномарки" => "http://www.chepetsk.ru/do/?id=auto&sid=inauto",
    "Отечественные" => "http://www.chepetsk.ru/do/?id=auto&sid=rusauto",
    "Запчасти" => "http://www.chepetsk.ru/do/?id=auto&sid=autozap",
    "Шины и диски" => "http://www.chepetsk.ru/do/?id=auto&sid=sd"
  },
  "Одежда, обувь и аксессуары" => {
    "Одежда" => "http://www.chepetsk.ru/do/?id=clothes&sid=od",
    "Обувь" => "http://www.chepetsk.ru/do/?id=clothes&sid=obuv",
    "Аксессуары" => "http://www.chepetsk.ru/do/?id=clothes&sid=acs",
    "Для беременных" => "http://www.chepetsk.ru/do/?id=clothes&sid=ber"
  },
  "Разное продам" => {
    "Разное продам"=> "http://www.chepetsk.ru/do/?id=other"
  },
  "Находки и потери" => { 
    "Находки и потери" => "http://www.chepetsk.ru/do/?id=nahodki" 
  },
  "Детское" => {
    "Одежда" => "http://www.chepetsk.ru/do/?id=kids&sid=ode",
    "Обувь" => "http://www.chepetsk.ru/do/?id=kids&sid=obu",
    "Коляски" => "http://www.chepetsk.ru/do/?id=kids&sid=kolyaski",
    "Питание" => "http://www.chepetsk.ru/do/?id=kids&sid=pitanie",
    "Разное" => "http://www.chepetsk.ru/do/?id=kids&sid=raznoe"
  },
  "Услуги" => {
    "Транспорт" => "http://www.chepetsk.ru/do/?id=uslugi&sid=transp",
    "Ремонт в квартире" => "http://www.chepetsk.ru/do/?id=uslugi&sid=remont",
    "Красота" => "http://www.chepetsk.ru/do/?id=uslugi&sid=krasota",
    "Разное" => "http://www.chepetsk.ru/do/?id=uslugi&sid=ect"
  },
  "Животные"        => {"Животные"       => "http://www.chepetsk.ru/do/?id=pets"},
  "Стройматериалы"  => {"Стройматериалы" => "http://www.chepetsk.ru/do/?id=stroymat"},
  "Спорттовары"     => {"Спорттовары"    => "http://www.chepetsk.ru/do/?id=sport"}
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

class Item < Struct.new(:text, :phone, :has_email, :author, :image, :image_big, :date); end

def main(fout)
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

  return msgs
rescue StandardError => e
  puts "Error: #{e.message}"
end

def getMsgs(url)
  res = []
  printf("\t%s: ",url)
  doc = Nokogiri::HTML(open(url))
  begin
    doc.at_css('#mainer > table  > tr > td > table  > tr:nth-child(2) > td').css('table > tr > td > table').each do |table|
      rows = table.css('tr')

      msg = Item.new
      msg[:text] = rows[0].css('td')[1].text
      msg[:phone] = rows[1].css('td b').text
      msg[:author] = rows[1].at_css('td').text.gsub(msg[:phone],'')
      msg[:date] = rows[1].css('td')[1].text.split('—')[1]
      image = rows[0].css('td')[2].at_css('a')['href'] rescue nil
      if image != nil
        filename = 'upload/' + (image.hash + 2**31).to_s + File.extname(image)
        msg[:image_big] = filename
        msg[:image] = image.gsub('big', 'small')
        download(image, filename)
      end
      res << msg
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
  IO.write(name, open(url).read)
rescue StandardError => e 
  puts "Fail download image #{url}:\n#{e.message}"
end

fout = File.open("out.json","w")

puts "Start"
messages = Parallel.map(URLS, in_processes: 8) do |part, values|
  p = {}
  values.each do |item, url|
    p[item] = getMessages(url) rescue nil
    #fout.puts JSON.pretty_generate(p)
    #fout.flush
  end
  { part => p }
end
fout.puts JSON.pretty_generate(messages)
fout.close
