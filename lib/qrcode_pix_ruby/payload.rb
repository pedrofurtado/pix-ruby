# frozen_string_literal: true

module QrcodePixRuby
  class Payload
    ID_PAYLOAD_FORMAT_INDICATOR                 = '00'.freeze
    ID_MERCHANT_ACCOUNT_INFORMATION             = '26'.freeze
    ID_MERCHANT_ACCOUNT_INFORMATION_GUI         = '00'.freeze
    ID_MERCHANT_ACCOUNT_INFORMATION_KEY         = '01'.freeze
    ID_MERCHANT_ACCOUNT_INFORMATION_DESCRIPTION = '02'.freeze
    ID_MERCHANT_CATEGORY_CODE                   = '52'.freeze
    ID_TRANSACTION_CURRENCY                     = '53'.freeze
    ID_TRANSACTION_AMOUNT                       = '54'.freeze
    ID_COUNTRY_CODE                             = '58'.freeze
    ID_MERCHANT_NAME                            = '59'.freeze
    ID_MERCHANT_CITY                            = '60'.freeze
    ID_ADDITIONAL_DATA_FIELD_TEMPLATE           = '62'.freeze
    ID_ADDITIONAL_DATA_FIELD_TEMPLATE_TXID      = '05'.freeze
    ID_CRC16                                    = '63'.freeze

    attr_accessor :pix_key,
                  :description,
                  :merchant_name,
                  :merchant_city,
                  :transaction_id,
                  :amount

    def payload
      p  = ''

      p += emv(ID_PAYLOAD_FORMAT_INDICATOR, '01')
      p += emv_merchant
      p += emv(ID_MERCHANT_CATEGORY_CODE, '0000')
      p += emv(ID_TRANSACTION_CURRENCY, '986')
      p += emv(ID_TRANSACTION_AMOUNT, amount)
      p += emv(ID_COUNTRY_CODE, 'BR')
      p += emv(ID_MERCHANT_NAME, merchant_name)
      p += emv(ID_MERCHANT_CITY, merchant_city)
      p += emv_additional_data

      p + crc16(p)
    end

    def base64
      ''
    end

    private

    def emv(id, value)
      size = value.to_s.length.to_s.rjust(2, '0')
      "#{id}#{size}#{value}"
    end

    def emv_merchant
      merchant_gui         = emv ID_MERCHANT_ACCOUNT_INFORMATION_GUI, 'br.gov.bcb.pix'
      merchant_pix_key     = emv ID_MERCHANT_ACCOUNT_INFORMATION_KEY, pix_key
      merchant_description = emv ID_MERCHANT_ACCOUNT_INFORMATION_DESCRIPTION, description

      emv ID_MERCHANT_ACCOUNT_INFORMATION, "#{merchant_gui}#{merchant_pix_key}#{merchant_description}"
    end

    def emv_additional_data
      txid = emv(ID_ADDITIONAL_DATA_FIELD_TEMPLATE_TXID, transaction_id)
      emv ID_ADDITIONAL_DATA_FIELD_TEMPLATE, txid
    end

    def crc16(t)
      extended_payload = "#{t}#{ID_CRC16}04"
      extended_payload_length = extended_payload.length
      polynomial = 0x1021
      result = 0xFFFF

      if extended_payload_length > 0
        offset = 0

        while offset < extended_payload_length
          result = result ^ (extended_payload[offset].bytes[0] << 8)

          bitwise = 0

          while bitwise < 8
            result = result << 1

            if result & 0x10000 != 0
              result = result ^ polynomial
            end

            result = result & 0xFFFF

            bitwise += 1
          end

          offset += 1
        end
      end

      "#{ID_CRC16}04#{result.to_s(16).upcase}"
    end
  end
end