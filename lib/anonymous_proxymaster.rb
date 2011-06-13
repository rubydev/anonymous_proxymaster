module AnonymousProxymaster

  class ProxyList

    # ----------------------------------------------------------------------------
    # Initialize
    # ----------------------------------------------------------------------------

    def initialize
      @logger = Logger.new("#{::Rails.root.to_s}/log/anonymous_proxymaster.log", "daily")
      @logger.formatter = Logger::Formatter.new

      @proxy_servers = []
      @bad_proxies = {}
    end

    # ----------------------------------------------------------------------------
    # Get proxy list from www.hidemyass.com
    # ----------------------------------------------------------------------------

    def get_proxy_list(total_page_number = 25)
      @proxy_servers = []

      (1..total_page_number).each do |p|
        doc = Hpricot(open("http://www.hidemyass.com/proxy-list/#{p}"))
        (doc/"table#listtable/tr").each do |line|
          ip = (line/"td[2]").inner_text.gsub(/\n/,"")
          port = (line/"td[3]").inner_text.gsub(/\n/,"")
          @proxy_servers << "#{ip}:#{port}"
        end
      end

      # remove bad proxies

      @logger.info(':   ProxyList.get_proxy_list()') {
        "Get new #{@proxy_servers.length} proxies" }

      rescue => e
        @logger.error(':   ProxyList.get_proxy_list()') {
          "Error: #{e.class} - #{e.message}" }
    end

    # ----------------------------------------------------------------------------
    # Push proxy to bad proxy list
    #  - if proxy 3x bad => remove from proxy servers list
    #  - if proxy list count < 5 => get new proxy list
    # ----------------------------------------------------------------------------

    def bad_proxy( proxy, force_remove = false )

      count = @bad_proxies[proxy]

      if force_remove
        @proxy_servers = @proxy_servers - [proxy]
        @logger.debug(':   ProxyList.bad_proxy()') {
          "Force remove proxy '#{proxy}' from proxy list" }
      # add proxy to bad proxy list
      elsif count.nil?
        @bad_proxies[proxy] = 0
      # remove proxy from ok proxy server list
      elsif count > 3
        @proxy_servers = @proxy_servers - [proxy]
        @logger.debug(':   ProxyList.bad_proxy()') {
          "Remove proxy '#{proxy}' from proxy list" }
      else
        @bad_proxies[proxy] += 1
      end

      # get new proxy list
      if @proxy_servers.length < 5
        get_proxy_list
        @bad_proxies = {}
      end

    end

    # ----------------------------------------------------------------------------
    # Return proxy servers list
    # ----------------------------------------------------------------------------

    def proxy_servers
      @proxy_servers
    end

    # ----------------------------------------------------------------------------
    # Return first proxy from list (first of all rotate proxy list)
    #  - return nil if proxy servers list is empty
    # ----------------------------------------------------------------------------

    def proxy
      @proxy_servers.length > 0 ? ( rotate_list; @proxy_servers.first ) : nil
    end

    # ----------------------------------------------------------------------------
    # Rotate proxy servers list
    # ----------------------------------------------------------------------------

    def rotate_list
      @proxy_servers.push @proxy_servers.shift
    end

    # ----------------------------------------------------------------------------
    # Test all proxies and remove bad proxies
    # ----------------------------------------------------------------------------

    def test_proxies
      @proxy_servers.each do |proxy|
        test_proxy(proxy)
      end
    end

    # ----------------------------------------------------------------------------
    # Test proxy
    # ----------------------------------------------------------------------------

    def test_proxy(proxy)
      open("http://google.com/search?q=site:google.com", :proxy => "http://#{proxy}")
      rescue Timeout::Error
        @proxy_servers = @proxy_servers - [proxy]
      rescue OpenURI::HTTPError
        @proxy_servers = @proxy_servers - [proxy]
      rescue
        @proxy_servers = @proxy_servers - [proxy]
    end

  end
end


