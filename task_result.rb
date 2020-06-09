# Тут находится программа, выполняющая обработку данных из файла.
# Тест показывает как программа должна работать.
# В этой программе нужно обработать файл данных data_large.txt.

# Задача:
# Оптимизировать программу;
# Программа должна корректно обработать файл data_large.txt;
# Провести рефакторинг при необходимости
# Представить время обработки до и после

# Результат:
# Воемя обработки до измерить не удалось
# Время обработки после: 43.418543 сек.

require 'json'
require 'pry'
require 'date'
require 'minitest/autorun'
require 'benchmark'
require 'set'

def parse_user(user)
  fields = user.split(',')
  {
    id:         fields[1].to_i,
    first_name: fields[2],
    last_name:  fields[3]
  }
end

def parse_session(session)
  fields            = session.split(',')
  year, month, date = fields[5].split('-').map(& :to_i)
  {
    user_id:    fields[1].to_i,
    session_id: fields[2].to_i,
    browser:    fields[3].upcase,
    time:       fields[4].to_i,
    date:       Date.new(year, month, date)
  }
end

# Собираем статистику по сессиям
def sessions_stat(sessions)
  {}.tap do |stat|
    stat['sessionsCount']    = sessions.count
    stat['totalTime']        = total_session_time(sessions)
    stat['longestSession']   = max_session_time(sessions)
    stat['browsers']         = user_browsers(sessions)
    stat['usedIE']           = ie_any?(sessions)
    stat['alwaysUsedChrome'] = chrome_always?(sessions)
    stat['dates']            = session_dates(sessions)
  end
end

# Собираем количество времени по пользователям
def total_session_time(sessions)
  "#{sessions.map {|s| s[:time]}.sum} min."
end

# Выбираем самую длинную сессию пользователя
def max_session_time(sessions)
  "#{sessions.map {|s| s[:time]}.max} min."
end

# Браузеры пользователя через запятую
def user_browsers(sessions)
  sessions.map {|s| s[:browser]}.sort.join(', ')
end

# Хоть раз использовал IE?
def ie_any?(sessions)
  sessions.map{|s| s[:browser]}.any? { |b| b =~ /INTERNET EXPLORER/ }
end

# Всегда использовал только Chrome?
def chrome_always?(sessions)
  sessions.map{|s| s[:browser]}.all? { |b| b =~ /CHROME/ }
end

# Даты сессий через запятую в обратном порядке в формате iso8601
def session_dates(sessions)
  sessions.map{|s| s[:date]}.sort.reverse.map { |d| d.iso8601 }
end

def work(filename = 'data.txt', output = 'result.json')
  file = File.foreach(filename)

  browsers = Set.new
  session_counter = 0
  result = {}

  file.each_entry do |line|
    cols = line.split(',')

    next if cols[0] != 'user' && cols[0] != 'session'

    if cols[0] == 'user'
      user = parse_user(line)
      result[user[:id]] ||= {}
      result[user[:id]] = user
    else
      session = parse_session(line)
      browsers << session[:browser]
      session_counter += 1
      result[session[:user_id]] ||= {}
      result[session[:user_id]][:sessions] ||= []
      result[session[:user_id]][:sessions] << session
    end
  end

  # Отчёт в json
  #   - Сколько всего юзеров +
  #   - Сколько всего уникальных браузеров +
  #   - Сколько всего сессий +
  #   - Перечислить уникальные браузеры в алфавитном порядке через запятую и капсом +
  #
  #   - По каждому пользователю
  #     - сколько всего сессий +
  #     - сколько всего времени +
  #     - самая длинная сессия +
  #     - браузеры через запятую +
  #     - Хоть раз использовал IE? +
  #     - Всегда использовал только Хром? +
  #     - даты сессий в порядке убывания через запятую +

  report = {}

  report['totalUsers'] = result.keys.count

  report['uniqueBrowsersCount'] = browsers.count

  report['totalSessions'] = session_counter

  report['allBrowsers'] = browsers.to_a.sort.join(',')

  # Статистика по пользователям
  report['usersStats'] = {}

  result.each do |key, user|
    user_key = "#{user[:first_name]} #{user[:last_name]}"
    report['usersStats'][user_key] = sessions_stat(user[:sessions])
  end

  File.write(output, "#{report.to_json}\n")
end


class Run
  start = Time.now
  work('data_large.txt', 'result_large.json')
  finish = Time.now
  p "Total time (sec): #{finish - start}"
end

class TestMe < Minitest::Test
  def setup
    File.write('result.json', '')
    File.write('data.txt',
'user,0,Leida,Cira,0
session,0,0,Safari 29,87,2016-10-23
session,0,1,Firefox 12,118,2017-02-27
session,0,2,Internet Explorer 28,31,2017-03-28
session,0,3,Internet Explorer 28,109,2016-09-15
session,0,4,Safari 39,104,2017-09-27
session,0,5,Internet Explorer 35,6,2016-09-01
user,1,Palmer,Katrina,65
session,1,0,Safari 17,12,2016-10-21
session,1,1,Firefox 32,3,2016-12-20
session,1,2,Chrome 6,59,2016-11-11
session,1,3,Internet Explorer 10,28,2017-04-29
session,1,4,Chrome 13,116,2016-12-28
user,2,Gregory,Santos,86
session,2,0,Chrome 35,6,2018-09-21
session,2,1,Safari 49,85,2017-05-22
session,2,2,Firefox 47,17,2018-02-02
session,2,3,Chrome 20,84,2016-11-25
')
  end

  def test_result
    work
    expected_result = '{"totalUsers":3,"uniqueBrowsersCount":14,"totalSessions":15,"allBrowsers":"CHROME 13,CHROME 20,CHROME 35,CHROME 6,FIREFOX 12,FIREFOX 32,FIREFOX 47,INTERNET EXPLORER 10,INTERNET EXPLORER 28,INTERNET EXPLORER 35,SAFARI 17,SAFARI 29,SAFARI 39,SAFARI 49","usersStats":{"Leida Cira":{"sessionsCount":6,"totalTime":"455 min.","longestSession":"118 min.","browsers":"FIREFOX 12, INTERNET EXPLORER 28, INTERNET EXPLORER 28, INTERNET EXPLORER 35, SAFARI 29, SAFARI 39","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-09-27","2017-03-28","2017-02-27","2016-10-23","2016-09-15","2016-09-01"]},"Palmer Katrina":{"sessionsCount":5,"totalTime":"218 min.","longestSession":"116 min.","browsers":"CHROME 13, CHROME 6, FIREFOX 32, INTERNET EXPLORER 10, SAFARI 17","usedIE":true,"alwaysUsedChrome":false,"dates":["2017-04-29","2016-12-28","2016-12-20","2016-11-11","2016-10-21"]},"Gregory Santos":{"sessionsCount":4,"totalTime":"192 min.","longestSession":"85 min.","browsers":"CHROME 20, CHROME 35, FIREFOX 47, SAFARI 49","usedIE":false,"alwaysUsedChrome":false,"dates":["2018-09-21","2018-02-02","2017-05-22","2016-11-25"]}}}' + "\n"
    assert_equal expected_result, File.read('result.json')
  end
end