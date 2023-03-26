#
# Matter_Plugin_Light3.be - implements the behavior for a Light with 3 channels (RGB)
#
# Copyright (C) 2023  Stephan Hadinger & Theo Arends
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Matter plug-in for core behavior

# dummy declaration for solidification
class Matter_Plugin end

#@ solidify:Matter_Plugin_Light3,weak

class Matter_Plugin_Light3 : Matter_Plugin
  static var CLUSTERS  = {
    # 0x001D: inherited                             # Descriptor Cluster 9.5 p.453
    0x0003: [0,1,0xFFFC,0xFFFD],                    # Identify 1.2 p.16
    0x0004: [0,0xFFFC,0xFFFD],                      # Groups 1.3 p.21
    0x0005: [0,1,2,3,4,5,0xFFFC,0xFFFD],            # Scenes 1.4 p.30 - no writable
    0x0006: [0,0xFFFC,0xFFFD],                      # On/Off 1.5 p.48
    0x0008: [0,0x0F,0x11,0xFFFC,0xFFFD],                # Level Control 1.6 p.57
    0x0300: [0,1,7,8,0xF,0x4001,0x400A,0xFFFC,0xFFFD],# Color Control 3.2 p.111
  }
  static var TYPES = { 0x010D: 2 }                  # Extended Color Light

  var shadow_hue, shadow_bri, shadow_sat
  var shadow_onoff                           # fake status for now # TODO

  #############################################################
  # Constructor
  def init(device, endpoint)
    super(self).init(device, endpoint)
    self.shadow_hue = 0
    # self.get_onoff()                        # read actual value
    # if tasmota_relay_index == nil     tasmota_relay_index = 0   end
    # self.tasmota_relay_index = tasmota_relay_index
  end

  #############################################################
  # Update shadow
  #
  def update_shadow()
    import light
    var light_status = light.get()
    var bri = light_status.find('bri', nil)
    var hue = light_status.find('hue', nil)
    var sat = light_status.find('sat', nil)
    var pow = light_status.find('power', nil)
    if bri != nil     self.shadow_bri = tasmota.scale_uint(bri, 0, 255, 0, 254)       end
    if hue != nil     self.shadow_hue = tasmota.scale_uint(hue, 0, 360, 0, 254)       end
    if sat != nil     self.shadow_sat = tasmota.scale_uint(sat, 0, 255, 0, 254)       end
    if pow != self.shadow_onoff self.attribute_updated(nil, 0x0006, 0x0000)   self.shadow_onoff = pow end
    if bri != self.shadow_bri   self.attribute_updated(nil, 0x0008, 0x0000)   self.shadow_bri = bri   end
    if hue != self.shadow_hue   self.attribute_updated(nil, 0x0300, 0x0000)   self.shadow_hue = hue   end
    if sat != self.shadow_sat   self.attribute_updated(nil, 0x0300, 0x0001)   self.shadow_sat = sat   end
  end

  # #############################################################
  # # Model
  # #
  # def set_onoff(v)
  #   tasmota.set_power(self.tasmota_relay_index, bool(v))
  #   self.get_onoff()
  # end
  # #############################################################
  # # get_onoff
  # #
  # # Update shadow and signal any change
  # def get_onoff()
  #   var state = tasmota.get_power(self.tasmota_relay_index)
  #   if state != nil
  #     if self.shadow_onoff != nil && self.shadow_onoff != bool(state)
  #       self.onoff_changed()      # signal any change
  #     end
  #     self.shadow_onoff = state
  #   end
  #   if self.shadow_onoff == nil   self.shadow_onoff = false   end     # avoid any `nil` value when initializing
  #   return self.shadow_onoff
  # end

  #############################################################
  # read an attribute
  #
  def read_attribute(session, ctx)
    import string
    var TLV = matter.TLV
    var cluster = ctx.cluster
    var attribute = ctx.attribute

    # ====================================================================================================
    if   cluster == 0x0003              # ========== Identify 1.2 p.16 ==========
      if   attribute == 0x0000          #  ---------- IdentifyTime / u2 ----------
        return TLV.create_TLV(TLV.U2, 0)      # no identification in progress
      elif attribute == 0x0001          #  ---------- IdentifyType / enum8 ----------
        return TLV.create_TLV(TLV.U1, 0)      # IdentifyType = 0x00 None
      elif attribute == 0xFFFC          #  ---------- FeatureMap / map32 ----------
        return TLV.create_TLV(TLV.U4, 0)    # no features
      elif attribute == 0xFFFD          #  ---------- ClusterRevision / u2 ----------
        return TLV.create_TLV(TLV.U4, 4)    # "new data model format and notation"
      end

    # ====================================================================================================
    elif cluster == 0x0004              # ========== Groups 1.3 p.21 ==========
      if   attribute == 0x0000          #  ----------  ----------
        return nil                      # TODO
      elif attribute == 0xFFFC          #  ---------- FeatureMap / map32 ----------
        return TLV.create_TLV(TLV.U4, 0)#
      elif attribute == 0xFFFD          #  ---------- ClusterRevision / u2 ----------
        return TLV.create_TLV(TLV.U4, 4)# "new data model format and notation"
      end

    # ====================================================================================================
    elif cluster == 0x0005              # ========== Scenes 1.4 p.30 - no writable ==========
      if   attribute == 0xFFFC          #  ---------- FeatureMap / map32 ----------
        return TLV.create_TLV(TLV.U4, 0)    # 0 = no Level Control for Lighting
      elif attribute == 0xFFFD          #  ---------- ClusterRevision / u2 ----------
        return TLV.create_TLV(TLV.U4, 4)    # 0 = no Level Control for Lighting
      end

    # ====================================================================================================
    elif cluster == 0x0006              # ========== On/Off 1.5 p.48 ==========
      if   attribute == 0x0000          #  ---------- OnOff / bool ----------
        return TLV.create_TLV(TLV.BOOL, self.shadow_onoff)
      elif attribute == 0xFFFC          #  ---------- FeatureMap / map32 ----------
        return TLV.create_TLV(TLV.U4, 0)    # 0 = no Level Control for Lighting
      elif attribute == 0xFFFD          #  ---------- ClusterRevision / u2 ----------
        return TLV.create_TLV(TLV.U4, 4)    # 0 = no Level Control for Lighting
      end

    # ====================================================================================================
    elif cluster == 0x0008              # ========== Level Control 1.6 p.57 ==========
      if   attribute == 0x0000          #  ---------- CurrentLevel / u1 ----------
        return TLV.create_TLV(TLV.U1, 0x88)
      elif attribute == 0x000F          #  ---------- Options / map8 ----------
        return TLV.create_TLV(TLV.U1, 0)    #
      elif attribute == 0x0011          #  ---------- OnLevel / u1 ----------
        return TLV.create_TLV(TLV.U1, 1)    #
      elif attribute == 0xFFFC          #  ---------- FeatureMap / map32 ----------
        return TLV.create_TLV(TLV.U4, 0X01)    # OnOff
      elif attribute == 0xFFFD          #  ---------- ClusterRevision / u2 ----------
        return TLV.create_TLV(TLV.U4, 5)    # "new data model format and notation"
      end
      
    # ====================================================================================================
    elif cluster == 0x0300              # ========== Color Control 3.2 p.111 ==========
      if   attribute == 0x0000          #  ---------- CurrentHue / u1 ----------
        return TLV.create_TLV(TLV.U1, self.shadow_hue)
      elif attribute == 0x0001          #  ---------- CurrentSaturation / u2 ----------
        return TLV.create_TLV(TLV.U1, self.shadow_sat)
      elif attribute == 0x0007          #  ---------- ColorTemperatureMireds / u2 ----------
        return TLV.create_TLV(TLV.U1, 0)
      elif attribute == 0x0008          #  ---------- ColorMode / u1 ----------
        return TLV.create_TLV(TLV.U1, 0)
      elif attribute == 0x000F          #  ---------- Options / u1 ----------
        return TLV.create_TLV(TLV.U1, 0)
      elif attribute == 0x4001          #  ---------- EnhancedColorMode / u1 ----------
        return TLV.create_TLV(TLV.U1, 0)
      elif attribute == 0x400A          #  ---------- ColorCapabilities / map2 ----------
        return TLV.create_TLV(TLV.U1, 0)
      elif attribute == 0xFFFC          #  ---------- FeatureMap / map32 ----------
        return TLV.create_TLV(TLV.U4, 0x01)    # HS
      elif attribute == 0xFFFD          #  ---------- ClusterRevision / u2 ----------
        return TLV.create_TLV(TLV.U4, 5)    # "new data model format and notation, FeatureMap support"
      end

    else
      return super(self).read_attribute(session, ctx)
    end
  end

  #############################################################
  # Invoke a command
  #
  # returns a TLV object if successful, contains the response
  #   or an `int` to indicate a status
  def invoke_request(session, val, ctx)
    var TLV = matter.TLV
    var cluster = ctx.cluster
    var command = ctx.command

    # ====================================================================================================
    if   cluster == 0x0003              # ========== Identify 1.2 p.16 ==========

      if   command == 0x0000            # ---------- Identify ----------
        # ignore
        return true
      elif command == 0x0001            # ---------- IdentifyQuery ----------
        # create IdentifyQueryResponse
        # ID=1
        #  0=Certificate (octstr)
        var iqr = TLV.Matter_TLV_struct()
        iqr.add_TLV(0, TLV.U2, 0)       # Timeout
        ctx.command = 0x00              # IdentifyQueryResponse
        return iqr
      elif command == 0x0040            # ---------- TriggerEffect ----------
        # ignore
        return true
      end
    # ====================================================================================================
    elif cluster == 0x0004              # ========== Groups 1.3 p.21 ==========
      # TODO
      return true
    # ====================================================================================================
    elif cluster == 0x0005              # ========== Scenes 1.4 p.30 ==========
      # TODO
      return true
    # ====================================================================================================
    elif cluster == 0x0006              # ========== On/Off 1.5 p.48 ==========
      if   command == 0x0000            # ---------- Off ----------
        self.set_onoff(false)
        return true
      elif command == 0x0001            # ---------- On ----------
        self.set_onoff(true)
        return true
      elif command == 0x0002            # ---------- Toggle ----------
        self.set_onoff(!self.get_onoff())
        return true
      end
    # ====================================================================================================
    elif cluster == 0x0008              # ========== Level Control 1.6 p.57 ==========
      if   command == 0x0000            # ---------- MoveToLevel ----------
        return true
      elif command == 0x0001            # ---------- Move ----------
        return true
      elif command == 0x0002            # ---------- Step ----------
        return true
      elif command == 0x0003            # ---------- Stop ----------
        return true
      elif command == 0x0004            # ---------- MoveToLevelWithOnOff ----------
        return true
      elif command == 0x0005            # ---------- MoveWithOnOff ----------
        return true
      elif command == 0x0006            # ---------- StepWithOnOff ----------
        return true
      elif command == 0x0007            # ---------- StopWithOnOff ----------
        return true
      end
    end
  end

  #############################################################
  # Signal that onoff attribute changed
  def onoff_changed()
    self.attribute_updated(nil, 0x0006, 0x0000)   # send to all endpoints
  end

  #############################################################
  # every_second
  def every_second()
    self.update_shadow()                    # force reading value and sending subscriptions
  end
end
matter.Plugin_Light3 = Matter_Plugin_Light3