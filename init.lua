wifitab={}
wifitab.ssid = "10"      -- wifi名
wifitab.pwd = "12345678"  --wifi密码
wifi.setmode(wifi.STATION)
wifi.sta.config(wifitab)
wifi.sta.connect()

timer1 = tmr.create()
timer2 = tmr.create()


ProductKey = ""        --阿里云三元组
DeviceName = ""
DeviceSecret = ""
RegionId = "cn-shanghai"
ESP8266ClientId = 202005

SubTopic="/sys/"..ProductKey.."/"..DeviceName.."/thing/service/property/set"           
Pubtopic="/sys/"..ProductKey.."/"..DeviceName.."/thing/event/property/post"

BrokerAddress = ProductKey..".iot-as-mqtt."..RegionId..".aliyuncs.com"
BrokerPort = 1883

HmacData = "clientId"..ESP8266ClientId.."deviceName"..DeviceName.."productKey"..ProductKey
MQTTClientId = ESP8266ClientId.."|securemode=3,signmethod=hmacsha1|"
MQTTUserName = DeviceName.."&"..ProductKey
MQTTPassword = encoder.toHex(crypto.hmac("sha1",HmacData,DeviceSecret))


function ConnectWifi()
    if wifi.sta.getip() == nil then
        print("Connecting...")
    else
        timer1:stop()
        print("Connect AP success")
        print(wifi.sta.getip())
        MQTTClient = mqtt.Client(MQTTClientId, 120, MQTTUserName, MQTTPassword, false)
        MQTTClient:connect(BrokerAddress, BrokerPort, false, function(client)
        
            timer1:stop()
            print("MQTT connect success")
            

            MQTTClient:subscribe(SubTopic,0,function(conm)
                 print("MQTT subscribe success")
                 MQTTOn()
            end)

        end,

        function(client,reason)
            print("MQTT connect fail:"..reason)
            timer1:alarm(5000, tmr.ALARM_AUTO, ConnectWifi)
        end)
    end
end 

function MQTTOn()
    print("MQTT listen...")
    MQTTClient:on("message",function(client,topic,data)
        print("\n")
        print(topic..":")
        print(data)
        if data == "1" then
            MQTTPublish()
        end
    end)
end

function MQTTPublish()
    data = {}
    ok,json = pcall(sjson.encode, {params=data})
    MQTTClient:publish(Pubtopic, json, 0, 0, function(client)
        print("Publish weather success")
    end)
end

timer1:alarm(5000, tmr.ALARM_AUTO, ConnectWifi)
