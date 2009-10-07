module RPXNow
  # Makes returned contacts feel like a array
  class ContactsCollection < Array
    def initialize(list)
      @raw = list
      @additional_info = list.reject{|k,v|k=='entry'}
      list['entry'].each{|item| self << parse_data(item)}
    end

    def additional_info;@additional_info;end
    def raw;@raw;end

    private

    def parse_data(entry)
      entry['emails'] = entry['emails'].map{|email| email['value']}
      entry
    end
  end
end