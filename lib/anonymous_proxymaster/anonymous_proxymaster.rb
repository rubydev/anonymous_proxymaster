# encoding: utf-8
module AnonymousProxymaster

  class ProxyList

    PROXY_PLAIN_FILES = [
      'http://multiproxy.org/txt_all/proxy.txt',
      'http://www.freeproxy.ru/download/lists/goodproxy.txt',
      'http://www.tubeincreaser.com/proxylist.txt',
      'http://hack72.2ch.net/otakara.cgi',
      'http://proxylists.net/http_highanon.txt',
      'http://proxylists.net/http.txt',
      'http://www.rmccurdy.com/scripts/proxy/good.txt',
      'http://www.freeproxy.ch/proxylight.txt',
      'http://www.greenforest.co.in/gb/proxy.txt',
      'http://rmccurdy.com/scripts/proxy/good.txt',
      'http://www.papilouve.com/divers/proxies2700.txt',
      'http://more-proxies.com/Proxy.txt',
      'http://more-proxies.com/Proxies.txt',
      'http://more-proxies.com/xproxy.txt',
      'http://www.angelfire.com/realm/frozenwater/proxies/proxies.txt',
      'http://proxiak.pl/proxy_all.txt',
      'http://computer-student.co.uk/proxy.txt',
      'http://vavricek.cs.vsb.cz/images/2/21/Proxy-list-POST-tested.txt',
      'http://www.searchlores.org/pxylist1.txt',
      'http://www.searchlores.org/pxylist2.txt',
      'http://www.tubeincreaser.com/proxylist.txt',
      'http://org.pc-freak.net/projects/anonproxys.txt',
      'http://www.papilouve.com/divers/proxies2700.txt',
      'http://www.airdemon.net/proxylist.txt',
      'http://rmccurdy.com/scripts/proxy/good.txt',
      'http://noseliteteam.net/_fr/1/anonymous.txt',
      'http://173.212.200.42/xr7/s1.txt',
      'http://173.212.200.42/xr7/s2.txt',
      'http://173.212.200.42/xr7/s3.txt',
      'http://173.212.200.42/xr7/s4.txt',
      'http://173.212.200.42/xr7/s5.txt',
      'http://173.212.200.42/xr7/s6.txt',
      'http://173.212.200.42/xr7/s7.txt',
      'http://173.212.200.42/xr7/s8.txt',
      'http://starskingvn.com/Proxies.txt',
      'ftp://89.105.158.144/Soft/Programm%20for%20TC7/KeyChecker/proxy.txt',
      'http://proxifier.at.ua/HttpsSocksv5-14-ordibehesht-.txt',
      'http://www.jhaazhum.com/wp-content/uploads/2012/04/proxy.txt',
      'http://file.oboz.ua/files/vf4f630068113d0_2012316105712.txt'
    ]

    # ----------------------------------------------------------------------------
    # Initialize
    # ----------------------------------------------------------------------------

    def initialize
      @logger = Logger.new("log/anonymous_proxymaster.log")
      @logger.formatter = Logger::Formatter.new

      @proxy_servers = []
      @bad_proxies = {}
    end

    # ----------------------------------------------------------------------------
    # Get proxy lists
    # ----------------------------------------------------------------------------

    def get_proxy_list
      @proxy_servers = []

      get_proxy_list_from_hidemyass_com
      get_proxy_list_from_valid_proxy_com
      get_proxy_list_from_cybersyndrome_net
      get_proxy_list_from_cz88_net
      get_proxy_list_from_xroxy_com

      PROXY_PLAIN_FILES.each{|url| get_proxy_list_from_textproxylists url }

      # remove duplicate proxies
      @proxy_servers = @proxy_servers.uniq

      @logger.info(':   ProxyList.get_proxy_list()') {
        "Get total #{@proxy_servers.length} new unique proxies" }

      rescue => e
        @logger.error(':   ProxyList.get_proxy_list()') {
          "Error: #{e.class} - #{e.message}" }
    end

    # ----------------------------------------------------------------------------
    # Get proxy list from text proxylists
    # ----------------------------------------------------------------------------

    def get_proxy_list_from_textproxylists url

      counter = 0
      doc = open(url).readlines
      doc.each do |line|
        next unless ip = line.strip.match(/(\d+\.\d+\.\d+\.\d+:\d+)/)
        @proxy_servers << ip[1]
        counter +=1
      end

      @logger.info(':   ProxyList.get_proxy_list_from_textproxylists()') {
        "Get new #{counter} proxies from '#{url}'" }

      rescue => e
        @logger.error(':   ProxyList.get_proxy_list_from_textproxylists()') {
          "Error for url '#{url}': #{e.class} - #{e.message}" }
    end

    # ----------------------------------------------------------------------------
    # Get proxy list from xroxy.com
    # ----------------------------------------------------------------------------

    def get_proxy_list_from_xroxy_com

      counter = 0
      (0..150).each do |p|
        page = open("http://www.xroxy.com/proxylist.php?pnum=#{p}")
        doc = Hpricot(page)
        (doc/"div#content/table[1]/tr").each do |line|
          ip = (line/"td[2]").inner_text.strip
          port = (line/"td[3]").inner_text.strip
          next unless port =~ /^\d+$/
          @proxy_servers << "#{ip}:#{port}"
          counter +=1
        end
      end

      @logger.info(':   ProxyList.get_proxy_list_from_xroxy_com()') {
        "Get new #{counter} proxies" }

      rescue => e
        @logger.error(':   ProxyList.get_proxy_list_from_xroxy_com()') {
          "Error: #{e.class} - #{e.message}" }
    end

    # ----------------------------------------------------------------------------
    # Get proxy list from cz88.net
    # ----------------------------------------------------------------------------

    def get_proxy_list_from_cz88_net

      counter = 0
      links = [ 'http://www.cz88.net/proxy/index.shtml' ]
      (2..10).each do |p|
        links << "http://www.cz88.net/proxy/http_#{p}.shtml"
      end

      links.each do |link|
        page = open(link)
        doc = Hpricot(page.read.encode('utf-8', 'gb18030'))
        (doc/"table/tr").each do |line|
          ip = (line/"td[1]").inner_text.gsub(/\n/m,"").strip
          port = (line/"td[2]").inner_text.gsub(/\n/m,"").strip
          next unless port =~ /^\d+$/
          @proxy_servers << "#{ip}:#{port}"
          counter +=1
        end
      end

      @logger.info(':   ProxyList.get_proxy_list_from_cz88_net()') {
        "Get new #{counter} proxies" }

      rescue => e
        @logger.error(':   ProxyList.get_proxy_list_from_cz88_net()') {
          "Error: #{e.class} - #{e.message}" }
    end


    # ----------------------------------------------------------------------------
    # Get proxy list from cybersyndrome.net
    # ----------------------------------------------------------------------------

    def get_proxy_list_from_cybersyndrome_net

      counter = 0
      links = [
        'http://www.cybersyndrome.net/plr5.html',
        'http://www.cybersyndrome.net/pla5.html',
        'http://www.cybersyndrome.net/pld5.html',
      ]

      links.each do |link|
        doc = Hpricot(open(link))
        (doc/"ol/li").each do |line|
          @proxy_servers << (line/"a").inner_text.strip
          counter +=1
        end
      end

      @logger.info(':   ProxyList.get_proxy_list_from_cybersyndrome_net()') {
        "Get new #{counter} proxies" }

      rescue => e
        @logger.error(':   ProxyList.get_proxy_list_from_cybersyndrome_net()') {
          "Error: #{e.class} - #{e.message}" }
    end

    # ----------------------------------------------------------------------------
    # Get proxy list from valid-proxy.com
    # ----------------------------------------------------------------------------

    def get_proxy_list_from_valid_proxy_com(total_page_number = 18)

      counter = 0
      (1..total_page_number).each do |p|
        doc = Hpricot(open("http://valid-proxy.com/en/proxylist/country/asc/#{p}"))
        (doc/"tr").each do |line|
          ip = (line/"td[1]").inner_text.gsub(/\n/,"")
          port = (line/"td[2]").inner_text.gsub(/\n/,"")
          next if ip == "0.0.0.0" || ip == "127.0.0.1"
          @proxy_servers << "#{ip}:#{port}"
          counter +=1
        end
      end

      @logger.info(':   ProxyList.get_proxy_list_from_valid_proxy_com()') {
        "Get new #{counter} proxies" }

      rescue => e
        @logger.error(':   ProxyList.get_proxy_list_from_valid_proxy_com()') {
          "Error: #{e.class} - #{e.message}" }
    end

    # ----------------------------------------------------------------------------
    # Get proxy list from www.hidemyass.com
    # ----------------------------------------------------------------------------

    def get_proxy_list_from_hidemyass_com(total_page_number = 30)

      counter = 0
      (1..total_page_number).each do |p|
        doc = Hpricot(open("http://www.hidemyass.com/proxy-list/#{p}"))
        (doc/"table#listtable/tr").each do |line|
          ip = (line/"td[2]").html.gsub(/\n/,"") \
            .gsub(/<span style="display:none">\d+<\/span>/i,'') \
            .gsub(/<div style="display:none">\d+<\/div>/i,'') \
            .gsub(/class="\d+"/i,'').gsub(/[^\d\.]/,'')
          port = (line/"td[3]").inner_text.gsub(/\n/,"")
          @proxy_servers << "#{ip}:#{port}"
          counter +=1
        end
      end

      @logger.info(':   ProxyList.get_proxy_list_from_hidemyass_com()') {
        "Get new #{counter} proxies" }

      rescue => e
        @logger.error(':   ProxyList.get_proxy_list_from_hidemyass_com()') {
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
      threads = []
      @proxy_servers.each do |proxy|
        threads << Thread.new {
          test_proxy(proxy)
        }
      end
      threads.each { |t| t.join}
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


