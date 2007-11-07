module Nanoc
  class PageProxy

    def initialize(page, params={})
      @page       = page
      @do_filter  = (params[:filter] != false)
    end

    def [](key)
      # Convert to a symbol and strip the ? if present
      real_key = key.to_s
      real_key = real_key[0..-2] if real_key.ends_with?('?')
      real_key = real_key.to_sym

      if real_key == :content and @do_filter
        @page.content
      elsif real_key == :file
        @page.file
      else
        @page.attribute_named(real_key)
      end
    end

    def []=(key, value)
      @page.attributes[key.to_sym] = value
    end

    def method_missing(method, *args)
      self[method]
    end

  end
end
