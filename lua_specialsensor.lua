

function send_msg()
   if parameter.action_udp then
      local msg
      local volt = 4.88 / 921 * adc.read(0)
      if rtcmem.read32(11) >= 1200 then
         rtcmem.write32(11, 0)
         msg = parameter.name .."," .. myIP .. ",Spannung gemessen," .. volt .. ",nix," .. 36000
      else
         msg = parameter.name .."," .. myIP .. ",Motion detected!," .. volt .. ",nix," .. 3600
      end
      rtcmem.write32(10, 0)
      
      local udp_skt = net.createUDPSocket()
      udp_skt:on("sent",function(s)
         print("Sende msg - dsleep")
         tmr.create():alarm(500, tmr.ALARM_SINGLE, function()
                      rtctime.dsleep(parameter.action_intervall*1000000 or 20*1000000, 4) -- 4 aufwachen ohne WiFi
                      end )
         -- 4, disable RF after deep-sleep wake up, just like modem sleep, there will be the smallest current
          end)
      print(msg)
      udp_skt:send(parameter.action_udp.port, parameter.action_udp.ip, msg)
   end
end

send_msg()
