require './epic.rb'

resolver = EPIC::CurrentUser.resolver
authInfo = EPIC::CurrentUser.authInfo

#handleValues = resolver.resolveHandle("10916/SARA")

# authInfo = hdllib.PublicKeyAuthenticationInfo.new(
  # '0.NA/10916',
  # 200,
  # hdllib.Util.getPrivateKeyFromBytes(
    # File.read('secrets/200_0_NA_10916'),
    # 0
  # )
# )



(1..1000).each do
  |i|
  puts i
  request = hdllib.CreateHandleRequest.new(
    "10916/SARA_#{i}".to_java_bytes,
    [
      hdllib.HandleValue.new(
        1,
        "URL".to_java_bytes,
        "http://www.sara.nl/#{i}".to_java_bytes
      )
    ].to_java( hdllib.HandleValue ),
    authInfo
  )
  response = resolver.processRequest request
  if(response.responseCode==hdllib.AbstractMessage::RC_SUCCESS)
    puts "==>SUCCESS["
  else
    puts "==>FAILURE[" + response.toString
  end
end