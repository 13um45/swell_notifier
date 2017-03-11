require 'httparty'


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

##
# weather elemement: returns an array for each day, total of 7 days
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
# tides element: returns an array of 4 tide objects low, high, low, high
# includes:
# tideTime, tideHeight_mt, tide_type, tideDateTime
response['data']['weather'][0]['tides'][0]['tide_data']