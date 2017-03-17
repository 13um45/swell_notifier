require 'httparty'

##
# weather element: returns an array for each day, total of 7 days
# includes:
# date, maxtempC, maxtempF, mintempC, mintempC, astronomy, hourly, tides
# day 1 = ['data']['weather'][0], day 2 ['data']['weather'][1], day 3 etc.
# response['data']['weather']

##
# hourly element: returns an array for each hour increment, i default this to 3 hour increments
# includes:
# time, tempC, tempF, windspeedMiles, windspeedKmph, winddirDegree, winddirection or winddir16Point, weatherCode,
# weatherDesc, weatherIconUrl, precipMM, humidity, visibility, pressure, cloudcover, sigHeight_m, swellHeight_m,
# swell_Height_ft, swellDir, swellDir16Point, swellPeriod_secs, waterTemp_C, waterTemp_F
# response['data']['weather'][0]['hourly']



##
# element: returns an array of 4 tide objects low, high, low, high
# includes:
# tideTime, tideHeight_mt, tide_type, tideDateTime
# response['data']['weather'][0]['tides'][0]['tide_data']

SHORE_DEGREE_DEFAULTS =  { south_fl: 6 }

SOUTH_FLORIDA = { miami_beach: { lat_long: '25.770,-80.130', shore_degree: SHORE_DEGREE_DEFAULTS[:south_fl] },
                  dania_beach: {lat_long: '26.053,-80.111', shore_degree: SHORE_DEGREE_DEFAULTS[:south_fl] },
                  pompano: { lat_long: '26.226,-80.089', shore_degree: SHORE_DEGREE_DEFAULTS[:south_fl] },
                  deerfield_beach: { lat_long: '26.316, -80.074', shore_degree: SHORE_DEGREE_DEFAULTS[:south_fl] },
                  boca_raton: { lat_long: '26.386,-80.065', shore_degree: SHORE_DEGREE_DEFAULTS[:south_fl]},
                  delray_beach: { lat_long: '26.458,-80.057', shore_degree: SHORE_DEGREE_DEFAULTS[:south_fl] },
                  boynton_beach: { lat_long: '26.529,-80.045', shore_degree: SHORE_DEGREE_DEFAULTS[:south_fl] },
                  lantana: { lat_long: '26.584,-80.036', shore_degree: SHORE_DEGREE_DEFAULTS[:south_fl]},
                  lake_worth: { lat_long: '26.613,-80.035', shore_degree: SHORE_DEGREE_DEFAULTS[:south_fl]},
                  palm_beach: { lat_long: '26.715,-80.032', shore_degree: SHORE_DEGREE_DEFAULTS[:south_fl]},
                  juno_beach: { lat_long: '26.894,-80.055', shore_degree: SHORE_DEGREE_DEFAULTS[:south_fl]} }

hash = { q: SOUTH_FLORIDA[:delray_beach][:lat_long], fx: 'yes', format: 'json', tp: '3', tide: 'yes', key: ENV['WWO_TOKEN']}

def build_request(req_attr)
  'https://api.worldweatheronline.com/premium/v1/marine.ashx?' + append_search_parameters(req_attr)
end



def append_search_parameters(params)
  string = ''
  params.each do |key, value|
    string += key.to_s + '=' + "#{value}" + '&' unless value.nil?
  end
  string = string.gsub(' ', '+')
  string[-1] = ''
  string
end


# response = HTTParty.get(build_request(hash))
# wave_height_3_hours_from_now = response['data']['weather'][0]['hourly'][0]['swellHeight_ft']



class DailyWeather
  attr_accessor :date, :max_temp, :min_temp, :astronomy, :hourly, :tides, :best_hour

  def initialize(daily_wx_attr)
    @date = daily_wx_attr['date']
    @max_temp = daily_wx_attr['maxtempF']
    @min_temp = daily_wx_attr['mintempF']
    @astronomy = daily_wx_attr['astronomy']
    @hourly = daily_wx_attr[:hourly_forecast]
    @tides = daily_wx_attr['tides']
    @best_hour = return_best_hour
  end

  private
  def return_best_hour
    daytime_arr = hourly[2,5]
    daytime_arr.max_by { |hour| hour.rating }
  end
end

class HourlyForecast
  attr_accessor :time, :temp, :wind_speed, :wind_direction, :weather_desc, :sig_height_m, :swell_height_ft,
                :swell_dir, :swell_period, :water_temp, :relative_wind_direction, :rating

  def initialize(hourly_fx_attr)
    @time = hourly_fx_attr['time']
    @temp = hourly_fx_attr['tempF']
    @wind_speed = hourly_fx_attr['windspeedMiles'].to_i
    @wind_direction = hourly_fx_attr['winddirDegree'].to_i
    @weather_desc = hourly_fx_attr['weatherDesc']
    @sig_height_m = hourly_fx_attr['sigHeight_m']
    @swell_height_ft = hourly_fx_attr['swellHeight_ft'].to_f
    @swell_dir = hourly_fx_attr['swellDir']
    @swell_period = hourly_fx_attr['swellPeriod_secs'].to_f
    @water_temp = hourly_fx_attr['waterTemp_F']
    @relative_wind_direction = return_relative_wind_direction(6, wind_direction)
    @rating = return_rating
  end

  private
  def return_rating
    (wind_score(relative_wind_direction, wind_speed) +
        swell_period_score(swell_period) +
        swell_size_score(swell_height_ft, swell_period)).round(2)
  end

  def return_relative_wind_direction(shore_degree, wind_direction)
    sideshore_1 = wind_direction_range(normalize_degrees(0 + shore_degree), false)
    sideshore_onshore_1 = wind_direction_range(normalize_degrees(45 + shore_degree), true)
    onshore = wind_direction_range(normalize_degrees(90 + shore_degree), false)
    sideshore_onshore_2 = wind_direction_range(normalize_degrees(135 + shore_degree), true)
    sideshore_2 = wind_direction_range(normalize_degrees(180 + shore_degree), false)
    sideshore_offshore_1 = wind_direction_range(normalize_degrees(225 + shore_degree), true)
    offshore = wind_direction_range(normalize_degrees(270 + shore_degree), false)
    sideshore_offshore_2 = wind_direction_range(normalize_degrees(315 + shore_degree), true)

    w_r = wind_direction_relative(wind_direction, shore_degree)

    if sideshore_1.include?(w_r)
      'sideshore'
    elsif sideshore_onshore_1.include?(w_r)
      'sideshore/onshore'
    elsif onshore.include?(w_r)
      'onshore'
    elsif sideshore_onshore_2.include?(w_r)
      'sideshore/onshore'
    elsif sideshore_2.include?(w_r)
      'sideshore'
    elsif sideshore_offshore_1.include?(w_r)
      'sideshore/offshore'
    elsif offshore.include?(w_r)
      'offshore'
    elsif sideshore_offshore_2.include?(w_r)
      'sideshore/offshore'
    elsif sideshore_3(shore_degree).include?(w_r)
      'sideshore'
    end
  end

  def normalize_degrees(degree)
    degree + 33.75
  end

  def wind_direction_relative(wind_direction, shore_degree)
    if wind_direction >= shore_degree
      normalize_degrees(wind_direction )
    elsif wind_direction < shore_degree
      normalize_degrees(wind_direction) + 360
    end
  end

  def sideshore_3(degree)
    if degree < 33.75
      start_of_range = degree + 360
      end_of_range = start_of_range + (33.75 - degree)
      (start_of_range..end_of_range)
    else
      end_of_range = 360 + degree + 33.75
      (degree..end_of_range)
    end
  end

  def wind_direction_range(degree, small_range_increment)
    degree_offset = small_range_increment ? 11.25 : 33.75
    start_of_range = degree - degree_offset
    end_of_range = degree + degree_offset
    (start_of_range..end_of_range)
  end

  def swell_period_score(swell_period)
    if swell_period >= 10
      20
    else
      swell_period * 2
    end
  end

  def swell_size_score(swell_size, swell_period)
    if swell_size >= 6
      60
    elsif (2..5).include?(swell_size)
      swell_size * swell_period
    elsif swell_size < 2
      0
    else
      swell_size * 10
    end
  end


  def wind_score(wind_direction, wind_speed)
    case wind_direction
      when 'offshore'
        20
      when 'sideshore/offshore'
        20 - wind_speed
      when 'sideshore'
        10 - wind_speed
      when 'sideshore/onshore'
        5 - wind_speed
      when 'onshore'
        0 - wind_speed
      else
        0
    end
  end
end

##
# N = 0
# E = 90
# S = 180
# W = 270

# - offshore = 276 + || - 33.75
# - onshore = 96 + || - 33.75
# - sideshoreN = 6 + || - 33.75
# - sideshoreS = 186 + || - 33.75


def day_objects(response)
  day_objects = []
  response['data']['weather'].each do |day|
    hourly_arr = []
    day['hourly'].each do |hour_increment|
      hourly_arr << HourlyForecast.new(hour_increment)
    end
    day[:hourly_forecast] = hourly_arr
    day_objects << DailyWeather.new(day)
  end
  day_objects
end

json_response = HTTParty.get(build_request(hash))

one_week = day_objects(json_response)
best_hourly(one_week)
