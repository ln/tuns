#--
#Copyright 2007 Nominet UK
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License. 
#You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0 
#
#Unless required by applicable law or agreed to in writing, software 
#distributed under the License is distributed on an "AS IS" BASIS, 
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
#See the License for the specific language governing permissions and 
#limitations under the License.
#++
require 'rubygems'
require 'test/unit'
require 'Net/DNS'
class TestMisc < Test::Unit::TestCase
  def test_wildcard
    # test to make sure that wildcarding works.
    #
    rr = Net::DNS::RR.create('*.t.net-dns.org 60 IN A 10.0.0.1')
    
    assert(rr, 'RR got made')
    
    assert_equal(rr.name,    '*.t.net-dns.org', 'Name is correct'   )
    assert_equal(60,      rr.ttl,               'TTL is correct'    )
    assert_equal('IN',   rr.rrclass,              'CLASS is correct'  )
    assert_equal('A',    rr.type,               'TYPE is correct'   )
    assert_equal('10.0.0.1', rr.address,        'Address is correct')
  end
  
  def test_misc
    
    #
    # Make sure the underscore in SRV hostnames work.
    #
    srv = Net::DNS::RR.create('_rvp._tcp.t.net-dns.org. 60 IN SRV 0 0 80 im.bastardsinc.biz')
    
    assert(!$@,  'No errors')
    assert(srv, 'SRV got made')
    
    
    #~ # Test that the 5.005 Use of uninitialized value at
    #~ # /usr/local/lib/perl5/site_perl/5.005/Net/DNS/RR.pm line 639. bug is gone
    rr = Net::DNS::RR.create('mx.t.net-dns.org 60 IN MX 10 a.t.net-dns.org')
    assert(rr, 'RR created')
    
    assert_equal(rr.preference, 10, 'Preference works')
    
    
    
    mx = Net::DNS::RR.create('mx.t.net-dns.org 60 IN MX 0 mail.net-dns.org')
    
    assert(mx.inspect =~ /0 mail.net-dns.org/) # was 'like'
    assert_equal(mx.preference, 0)
    assert_equal(mx.exchange, 'mail.net-dns.org')
    
    srv = Net::DNS::RR.create('srv.t.net-dns.org 60 IN SRV 0 2 3 target.net-dns.org')
    
    p srv.inspect
    assert(srv.inspect =~ /0 2 3 target.net-dns.org\./)
    assert_equal(srv.rdatastr, '0 2 3 target.net-dns.org.')
    
    
    
  end
  
  def test_TXT_RR
    
    #
    #
    # Below are some thests that have to do with TXT RRs 
    #
    #
    
    
    # QUESTION SECTION:
    #txt2.t.net-dns.org.		IN	TXT
    
    # ANSWER SECTION:
    #txt2.t.net-dns.org.	60	IN	TXT	"Net-DNS\ complicated $tuff" "sort of \" text\ and binary \000 data"
    
    # AUTHORITY SECTION:
    #net-dns.org.		3600	IN	NS	ns1.net-dns.org.
    #net-dns.org.		3600	IN	NS	ns.ripe.net.
    #net-dns.org.		3600	IN	NS	ns.hactrn.net.
    
    # ADDITIONAL SECTION:
    #ns1.net-dns.org.	3600	IN	A	193.0.4.49
    #ns1.net-dns.org.	3600	IN	AAAA
    
    uuencodedPacket=%w{
11 99 85 00 00 01
00 01 00 03 00 02 04 74  78 74 32 01 74 07 6e 65
74 2d 64 6e 73 03 6f 72  67 00 00 10 00 01 c0 0c
00 10 00 01 00 00 00 3c  00 3d 1a 4e 65 74 2d 44
4e 53 3b 20 63 6f 6d 70  6c 69 63 61 74 65 64 20
24 74 75 66 66 21 73 6f  72 74 20 6f 66 20 22 20
74 65 78 74 3b 20 61 6e  64 20 62 69 6e 61 72 79
20 00 20 64 61 74 61 c0  13 00 02 00 01 00 00 0e
10 00 06 03 6e 73 31 c0  13 c0 13 00 02 00 01 00
00 0e 10 00 0d 02 6e 73  04 72 69 70 65 03 6e 65
74 00 c0 13 00 02 00 01  00 00 0e 10 00 0c 02 6e
73 06 68 61 63 74 72 6e  c0 93 c0 79 00 01 00 01
00 00 0e 10 00 04 c1 00  04 31 c0 79 00 1c 00 01
00 00 0e 10 00 10 20 01  06 10 02 40 00 03 00 00
12 34 be 21 e3 1e                               
}
    
    uuencodedPacket.map!{|e| e.hex}
    packetdata = uuencodedPacket.pack('c*')
    packetdata.gsub!("\s*", "")
    
    packet     = Net::DNS::Packet.new_from_binary(packetdata)
    txtRr=(packet.answer)[0]
    assert_equal('Net-DNS; complicated $tuff',(txtRr.char_str_list())[0],"First Char string in TXT RR read from wireformat")
    
    # Compare the second char_str this contains a NULL byte (space NULL
    # space=200020 in hex)
    
    temp = (txtRr.char_str_list())[1].unpack('H*')[0]
    #assert_equal(unpack('H*',(TXTrr.char_str_list())[1]),"736f7274206f66202220746578743b20616e642062696e61727920002064617461", "Second Char string in TXT RR read from wireformat")
    assert_equal("736f7274206f66202220746578743b20616e642062696e61727920002064617461", temp,"Second Char string in TXT RR read from wireformat")
    
    
    txtRr2=Net::DNS::RR.create('txt2.t.net-dns.org.	60	IN	TXT  "Test1 \" \ more stuff"  "Test2"')
    
    assert_equal((txtRr2.char_str_list())[0],'Test1 "  more stuff', "First arg string in TXT RR read from zonefileformat")
    assert_equal((txtRr2.char_str_list())[1],'Test2',"Second Char string in TXT RR read from zonefileformat")
    
    
    txtRr3   = Net::DNS::RR.create("baz.example.com 3600 HS TXT '\"' 'Char Str2'")
    
    assert_equal( (txtRr3.char_str_list())[0],'"',"Escaped \" between the  single quotes")
  end
end