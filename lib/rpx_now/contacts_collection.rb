module RPXNow
  class ContactsCollection < Array
    def initialize(list)
      list['entry'].each{|item| self << parse_data(item)}
    end

    private

    def parse_data(entry)
      entry['emails'] = entry['emails'].map{|email| email['value']}
      entry
    end
  end
end