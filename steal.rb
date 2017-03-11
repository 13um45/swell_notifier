require 'httparty'


SOUTH_FLORIDA = { miami_beach: '25.770,-80.130', dania_beach: '26.053,-80.111', pompano: '26.226,-80.089',
              deerfield_beach: '26.316, -80.074', boca_raton: '26.386,-80.065', delray_beach: '26.458,-80.057',
              boynton_beach: '26.529,-80.045', lantana: '26.584,-80.036', lake_worth: '26.613,-80.035',
              palm_beach: '26.715,-80.032', juno_beach: '26.894,-80.055' }

hash = { q: '26.460,-80.0566', fx: 'yes', format: 'json', tp: '3', tide: 'yes', key: 'd276dc59474d4f4196634625170903'}

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


response = HTTParty.get(build_request(hash))
wave_height_3_hours_from_now = response['data']['weather'][0]['hourly'][0]['swellHeight_ft']

post_me = HTTParty.post('https://api.pushover.net/1/messages.json', body: { token: 'a31eit4aavmqdzuqb52q9rzcra76ii', user: 'uig5r341c9gjp54evy28dp63adr397',
                                                                                message: "wave size in 3 hours #{wave_height_3_hours_from_now}"})


class DailyWeather
  attr_accessor :date, :max_temp, :min_temp, :astronomy, :hourly, :tides

  def initialize(daily_wx_attr)
    @date = daily_wx_attr['date']
    @max_temp = daily_wx_attr['maxtempF']
    @min_temp = daily_wx_attr['mintempF']
    @astronomy = daily_wx_attr['astronomy']
    @hourly = daily_wx_attr['hourly']
    @tides = daily_wx_attr['tides']
  end
end

class HourlyForecast
  attr_accessor :time, :temp, :windspeed_miles, :wind_direction, :weather_desc, :cloudcover, :sig_height_m, :swell_height_ft,
                :swell_dir, :swell_period, :water_temp

  def initialize(hourly_fx_attr)
    @time = hourly_fx_attr['time']
    @temp = hourly_fx_attr['tempF']
    @windspeed_miles = hourly_fx_attr['windspeedMiles']
    @wind_direction = hourly_fx_attr['winddir16Point']
    @weather_desc = hourly_fx_attr['weatherDesc']
    @cloudcover = hourly_fx_attr['cloudcover']
    @sig_height_m = hourly_fx_attr['sigHeight_m']
    @swell_height_ft = hourly_fx_attr['swell_Height_ft']
    @swell_dir = hourly_fx_attr['swellDir16Point']
    @swell_period = hourly_fx_attr['swellPeriod_secs']
    @water_temp = hourly_fx_attr['waterTemp_F']
  end
end

##
# weather element: returns an array for each day, total of 7 days
# includes:
# date, maxtempC, maxtempF, mintempC, mintempC, astronomy, hourly, tides
# day 1 = ['data']['weather'][0], day 2 ['data']['weather'][1], day 3 etc.
response['data']['weather']

##
# hourly element: returns an array for each hour increment, i default this to 3 hour increments
# includes:
# time, tempC, tempF, windspeedMiles, windspeedKmph, winddirDegree, winddirection or winddir16Point, weatherCode,
# weatherDesc, weatherIconUrl, precipMM, humidity, visibility, pressure, cloudcover, sigHeight_m, swellHeight_m,
# swell_Height_ft, swellDir, swellDir16Point, swellPeriod_secs, waterTemp_C, waterTemp_F
response['data']['weather'][0]['hourly']



##
# element: returns an array of 4 tide objects low, high, low, high
# includes:
# tideTime, tideHeight_mt, tide_type, tideDateTime
response['data']['weather'][0]['tides'][0]['tide_data']