module AnonymousProxymaster

  class ProxyList

    # ----------------------------------------------------------------------------
    # Initialize
    # ----------------------------------------------------------------------------

    def initialize
      @logger = Logger.new("#{RAILS_ROOT}/log/anonymous_proxymaster.log", "daily")
      @logger.formatter = Logger::Formatter.new

      @proxy_servers = []
      @bad_proxies = {}
      get_proxy_list
    end

    # ----------------------------------------------------------------------------
    # Get proxy list from www.hidemyass.com
    # ----------------------------------------------------------------------------

    def get_proxy_list
      @proxy_servers = []

      # 25 is total page number
      (1..25).each do |p|
        doc = Hpricot(open("http://www.hidemyass.com/proxy-list/#{p}"))
        (doc/"table#listtable/tr").each do |line|
          ip = (line/"td[2]").inner_text.gsub(/\n/,"")
          port = (line/"td[3]").inner_text.gsub(/\n/,"")
          @proxy_servers << "#{ip}:#{port}"
        end
      end

      @logger.info(':   ProxyServersList.get_proxy_list()') { "Get new #{@proxy_servers.length} proxies" }

      rescue => e
        @logger.error(':   ProxyServersList.get_proxy_list()') { "Error: #{e.class} - #{e.message}" }
    end

    # ----------------------------------------------------------------------------
    # Push proxy to bad proxy list
    #  - if proxy 10x bad => remove from proxy servers list
    #  - if proxy list count < 30 => get new proxy list
    # ----------------------------------------------------------------------------

    def bad_proxy( proxy )

      # add proxy to bad proxy list
      count = @bad_proxies[proxy]
      if count.nil?
        @bad_proxies[proxy] = 0
      # remove proxy from ok proxy server list
      elsif count > 10
        @proxy_servers = @proxy_servers - [proxy]
      else
        @bad_proxies[proxy] += 1
      end

      # get new proxy list
      if @proxy_servers.length < 30
        get_proxy_list
        @bad_proxies = {}
      end

      @logger.debug(':   ProxyServersList.get_proxy_list()') {
        "Bad (#{@bad_proxies.length}) and OK (#{@proxy_servers.length}) proxies count" }

    end

    # ----------------------------------------------------------------------------
    # Return proxy servers list
    # ----------------------------------------------------------------------------

    def proxy_servers
      @proxy_servers
    end

    # ----------------------------------------------------------------------------
    # Return first proxy from list
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

  end
end
