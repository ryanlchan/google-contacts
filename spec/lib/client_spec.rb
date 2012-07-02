require "spec_helper"

describe GContacts::Client do
  include Support::ResponseMock

  context "contact" do
    it "loads all" do
      mock_response(File.read("spec/responses/contacts/all.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_get).with("/m8/feeds/contacts/default/full?updated-min=1234", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234")
      contacts = client.all(:params => {"updated-min" => "1234"})

      contacts.id.should == "john.doe@gmail.com"
      contacts.updated.to_s.should == "2012-04-05T21:46:31.537Z"
      contacts.title.should == "Johnny's Contacts"
      contacts.author.should == {"name" => "Johnny", "email" => "john.doe@gmail.com"}
      contacts.next_uri.should be_nil
      contacts.per_page.should == 25
      contacts.start_index.should == 1
      contacts.total_results.should == 4
      contacts.should have(4).items

      contact = contacts.first
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/fd8fb1a55f2916e"
      contact.title.should == "Steve Stephson"
      contact.updated.to_s.should == "2012-02-06T01:14:56+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/fd8fb1a55f2916e")
      contact.etag.should == '"OWUxNWM4MTEzZjEyZTVjZTQ1Mjgy."'
      contact.data.should == {"gd:name" => [{"gd:fullName" => "Steve Stephson", "gd:givenName" => "Steve", "gd:familyName" => "Stephson"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve.stephson@gmail.com", "@primary" => "true"}, {"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve@gmail.com"}], "gd:phoneNumber" => [{"text" => "3005004000", "@rel" => "http://schemas.google.com/g/2005#mobile"}, {"text" => "+130020003000", "@rel" => "http://schemas.google.com/g/2005#work"}]}

      contact = contacts[1]
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/894bc75ebb5187d"
      contact.title.should == "Jill Doe"
      contact.updated.to_s.should == "2011-07-01T18:08:32+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/894bc75ebb5187d")
      contact.etag.should == '"ZGRhYjVhMTNkMmFhNzJjMzEyY2Ux."'
      contact.data.should == {"gd:name" => [{"gd:fullName" => "Jill Doe", "gd:givenName" => "Jill", "gd:familyName" => "Doe"}]}

      contact = contacts[2]
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/cd046ed518f0fb0"
      contact.title.should == 'Dave "Terry" Pratchett'
      contact.updated.to_s.should == "2011-06-29T23:11:57+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/cd046ed518f0fb0")
      contact.etag.should == '"ZWVhMDQ0MWI0MWM0YTJkM2MzY2Zh."'
      contact.data.should == {"gd:name" => [{"gd:fullName" => "Dave \"Terry\" Pratchett", "gd:givenName" => "Dave", "gd:additionalName" => "\"Terry\"", "gd:familyName" => "Pratchett"}], "gd:organization" => [{"gd:orgName" => "Foo Bar Inc", "@rel" => "http://schemas.google.com/g/2005#work"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#home", "@address" => "dave.pratchett@gmail.com", "@primary" => "true"}], "gd:phoneNumber" => [{"text" => "7003002000", "@rel" => "http://schemas.google.com/g/2005#mobile"}]}

      contact = contacts[3]
      contact.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/a1941d3d13cdc66"
      contact.title.should == "Jane Doe"
      contact.updated.to_s.should == "2012-04-04T02:08:37+00:00"
      contact.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/a1941d3d13cdc66")
      contact.etag.should == '"Yzg3MTNiODJlMTRlZjZjN2EyOGRm."'
      contact.data.should == {"gd:name" => [{"gd:fullName" => "Jane Doe", "gd:givenName" => "Jane", "gd:familyName" => "Doe"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#home", "@address" => "jane.doe@gmail.com", "@primary" => "true"}], "gd:phoneNumber" => [{"text" => "16004003000", "@rel" => "http://schemas.google.com/g/2005#mobile"}], "gd:structuredPostalAddress" => [{"gd:formattedAddress" => "5 Market St\n        San Francisco\n        CA", "gd:street" => "5 Market St", "gd:city" => "San Francisco", "gd:region" => "CA", "@rel" => "http://schemas.google.com/g/2005#home"}]}
    end

    it "paginates through all" do
      request_uri = ["/m8/feeds/contacts/default/full", "/m8/feeds/contacts/john.doe%40gmail.com/full?start-index=3&max-results=2", "/m8/feeds/contacts/john.doe%40gmail.com/full?start-index=5&max-results=2"]
      request_uri.each_index do |i|
        res_mock = mock("Response#{i}")
        res_mock.stub(:body).and_return(File.read("spec/responses/contacts/paginate_all_#{i}.xml"))
        res_mock.stub(:code).and_return("200")
        res_mock.stub(:message).and_return("OK")
        res_mock.stub(:header).and_return({})

        http_mock = mock("HTTP#{i}")
        http_mock.should_receive(:use_ssl=).with(true)
        http_mock.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
        http_mock.should_receive(:start)
        http_mock.should_receive(:request_get).with(request_uri[i], anything).and_return(res_mock)

        Net::HTTP.should_receive(:new).ordered.once.and_return(http_mock)
      end

      expected_titles = ["Jack 1", "Jack 2", "Jack 3", "Jack 4", "Jack 5"]

      client = GContacts::Client.new(:access_token => "12341234")
      client.paginate_all.each do |entry|
        entry.title.should == expected_titles.shift
      end

      expected_titles.should have(0).items
    end

    it "gets a single one" do
      mock_response(File.read("spec/responses/contacts/get.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_get).with("/m8/feeds/contacts/default/full/908f380f4c2f81?a=1", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234")
      element = client.get("908f380f4c2f81", :params => {:a => 1})

      element.should be_a_kind_of(GContacts::Element)
      element.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8"
      element.title.should == "Casey"
      element.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8")
    end

    it "creates a new one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new
      element.category = "contact"
      element.title = "Foo Bar"
      element.data = {"gd:name" => {"gd:fullName" => "Foo Bar", "gd:givenName" => "Foo Bar"}, "gd:email" => {"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "casey@gmail.com", "@primary" => true}}

      mock_response(File.read("spec/responses/contacts/create.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_post).with("/m8/feeds/contacts/default/full", "<?xml version='1.0' encoding='UTF-8'?>\n#{element.to_xml}", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      created = client.create!(element)
      created.should be_a_kind_of(GContacts::Element)
      created.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/32c39d7106a538e"
      created.title.should == "Foo Bar"
      created.data.should == {"gd:name" => [{"gd:fullName" => "Foo Bar", "gd:givenName" => "Foo Bar"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "casey@gmail.com", "@primary" => "true"}]}
      created.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/32c39d7106a538e")
    end

    it "updates an existing one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new(Nori.parse(File.read("spec/responses/contacts/update.xml"))["entry"])
      element.title.should == 'Foo "Doe" Bar'

      mock_response(File.read("spec/responses/contacts/update.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_put).with("/m8/feeds/contacts/default/base/32c39d7106a538e", "<?xml version='1.0' encoding='UTF-8'?>\n#{element.to_xml}", hash_including("Authorization" => "Bearer 12341234", "If-Match" => element.etag)).and_return(res_mock)
      end

      updated = client.update!(element)
      updated.should be_a_kind_of(GContacts::Element)
      updated.id.should == "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/32c39d7106a538e"
      updated.title.should == 'Foo "Doe" Bar'
      updated.data.should == {"gd:name" => [{"gd:fullName" => "Foo \"Doe\" Bar", "gd:givenName" => "Foo Bar", "gd:additionalName" => "\"Doe\""}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "casey@gmail.com", "@primary" => "true"}, {"@rel" => "http://schemas.google.com/g/2005#work", "@address" => "foo.bar@gmail.com"}]}
      updated.edit_uri.should == URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/32c39d7106a538e")
    end

    it "deletes an existing one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new(Nori.parse(File.read("spec/responses/contacts/update.xml"))["entry"])

      mock_response(File.read("spec/responses/contacts/update.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request) do |request|
          request.path.should == "/m8/feeds/contacts/default/base/32c39d7106a538e"
          request.to_hash["if-match"].should == [element.etag]
          request.to_hash["authorization"].should == ["Bearer 12341234"]

          res_mock
        end
      end

      client.delete!(element)
    end

    it "batch creates without an error" do
      Time.any_instance.stub(:iso8601).and_return("2012-04-06T06:02:04Z")

      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new
      element.title = "foo bar"
      element.content = "Bar Foo"
      element.data = {"gd:name" => [{"gd:givenName" => "foo bar"}]}
      element.category = "contact"
      element.create

      mock_response(File.read("spec/responses/contacts/batch_success.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_post) do |uri, data, headers|
          uri.should == "/m8/feeds/contacts/default/full/batch"
          headers.should include("Authorization" => "Bearer 12341234")

          Nori.parse(data).should == {"feed" => {"atom:entry" => {"batch:id" => "create", "batch:operation" => {"@type" => "insert"}, "atom:category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "atom:content" => "Bar Foo", "atom:title" => "foo bar", "gd:name" => {"gd:givenName" => "foo bar"}, "@xmlns:atom" => "http://www.w3.org/2005/Atom", "@xmlns:gd" => "http://schemas.google.com/g/2005"}, "@xmlns" => "http://www.w3.org/2005/Atom", "@xmlns:gContact" => "http://schemas.google.com/contact/2008", "@xmlns:gd" => "http://schemas.google.com/g/2005", "@xmlns:batch" => "http://schemas.google.com/gdata/batch"}}

          res_mock
        end
      end

      results = client.batch!([element])
      results.should have(1).item
      result = results.first
      result.data.should == {"gd:name" => [{"gd:fullName" => "foo bar", "gd:givenName" => "foo bar"}]}
      result.batch.should == {"status" => "create", "code" => "201", "reason" => "Created", "operation" => "insert"}
    end

    it "batch creates with an error" do
      Time.any_instance.stub(:iso8601).and_return("2012-04-06T06:02:04Z")

      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new
      element.title = "foo bar"
      element.content = "Bar Foo"
      element.data = {"gd:name" => [{"gd:givenName" => "foo bar"}]}
      element.category = "contact"
      element.create

      mock_response(File.read("spec/responses/contacts/batch_error.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_post) do |uri, data, headers|
          uri.should == "/m8/feeds/contacts/default/full/batch"
          headers.should include("Authorization" => "Bearer 12341234")

          Nori.parse(data).should == {"feed" => {"atom:entry" => {"batch:id" => "create", "batch:operation" => {"@type" => "insert"}, "atom:category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "atom:content" => "Bar Foo", "atom:title" => "foo bar", "gd:name" => {"gd:givenName" => "foo bar"}, "@xmlns:atom" => "http://www.w3.org/2005/Atom", "@xmlns:gd" => "http://schemas.google.com/g/2005"}, "@xmlns" => "http://www.w3.org/2005/Atom", "@xmlns:gContact" => "http://schemas.google.com/contact/2008", "@xmlns:gd" => "http://schemas.google.com/g/2005", "@xmlns:batch" => "http://schemas.google.com/gdata/batch"}}

          res_mock
        end
      end

      results = client.batch!([element])
      results.should have(1).item
      result = results.first
      result.data.should == {}
      result.batch.should == {"status" => {"parsed" => 0, "success" => 0, "error" => 0, "unprocessed" => 0}, "code" => "400", "reason" => "[Line 5, Column 35, element atom:entry] Invalid type for batch:operation: 'create'"}
    end
  end

  context "groups" do
    it "loads all" do
      mock_response(File.read("spec/responses/groups/all.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_get).with("/m8/feeds/groups/default/full?updated-min=1234", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)
      groups = client.all(:params => {"updated-min" => "1234"})

      groups.id.should == "john.doe@gmail.com"
      groups.updated.to_s.should == "2012-04-05T22:32:03+00:00"
      groups.title.should == "Johnny's Contact Groups"
      groups.author.should == {"name" => "Johnny", "email" => "john.doe@gmail.com"}
      groups.next_uri.should be_nil
      groups.per_page.should == 25
      groups.start_index.should == 1
      groups.total_results.should == 2
      groups.should have(2).items

      group = groups.first
      group.id.should == "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"
      group.title.should == "System Group: My Contacts"
      group.updated.to_s.should == "1970-01-01T00:00:00+00:00"
      group.edit_uri.should be_nil
      group.etag.should == '"YWJmYzA."'
      group.data.should have(0).items

      group = groups[1]
      group.id.should == "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/ada43d293fdb9b1"
      group.title.should == "Misc"
      group.updated.to_s.should == "2009-08-17T20:33:20+00:00"
      group.edit_uri.should == URI("https://www.google.com/m8/feeds/groups/john.doe%40gmail.com/full/ada43d293fdb9b1")
      group.etag.should == '"QXc8cDVSLyt7I2A9WxNTFUkLRQQ."'
      group.data.should have(0).items
    end

    it "paginates through all" do
      request_uri = ["/m8/feeds/groups/default/full", "/m8/feeds/groups/john.doe%40gmail.com/full?start-index=2&max-results=1"]
      request_uri.each_index do |i|
        res_mock = mock("Response#{i}")
        res_mock.stub(:body).and_return(File.read("spec/responses/groups/paginate_all_#{i}.xml"))
        res_mock.stub(:code).and_return("200")
        res_mock.stub(:message).and_return("OK")
        res_mock.stub(:header).and_return({})

        http_mock = mock("HTTP#{i}")
        http_mock.should_receive(:use_ssl=).with(true)
        http_mock.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
        http_mock.should_receive(:start)
        http_mock.should_receive(:request_get).with(request_uri[i], anything).and_return(res_mock)

        Net::HTTP.should_receive(:new).ordered.once.and_return(http_mock)
      end

      expected_titles = ["Misc 1", "Misc 2"]

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)
      client.paginate_all.each do |entry|
        entry.title.should == expected_titles.shift
      end

      expected_titles.should have(0).items
    end

    it "gets a single one" do
      mock_response(File.read("spec/responses/groups/get.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_get).with("/m8/feeds/groups/default/full/908f380f4c2f81?a=1", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)
      element = client.get("908f380f4c2f81", :params => {:a => 1})

      element.should be_a_kind_of(GContacts::Element)
      element.id.should == "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"
      element.title.should == "System Group: My Contacts"
      element.edit_uri.should be_nil
      element.etag.should == '"YWJmYzA."'
    end

    it "creates a new one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new
      element.category = "group"
      element.title = "Foo Bar"
      element.content = "Foo Bar"

      mock_response(File.read("spec/responses/groups/create.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_post).with("/m8/feeds/groups/default/full", "<?xml version='1.0' encoding='UTF-8'?>\n#{element.to_xml}", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      created = client.create!(element)
      created.should be_a_kind_of(GContacts::Element)
      created.id.should == "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/005d057b3b3d42a"
      created.title.should == "Foo Bar"
      created.data.should == {}
      created.edit_uri.should == URI("https://www.google.com/m8/feeds/groups/john.doe%40gmail.com/full/005d057b3b3d42a")
    end

    it "updates an existing one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new(Nori.parse(File.read("spec/responses/groups/update.xml"))["entry"])
      element.title.should == "Bar Bar"
      element.content.should == "Bar Bar"

      mock_response(File.read("spec/responses/groups/update.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_put).with("/m8/feeds/groups/default/base/3f93e3738e811d63", "<?xml version='1.0' encoding='UTF-8'?>\n#{element.to_xml}", hash_including("Authorization" => "Bearer 12341234", "If-Match" => element.etag)).and_return(res_mock)
      end

      updated = client.update!(element)
      updated.should be_a_kind_of(GContacts::Element)
      updated.id.should == "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/3f93e3738e811d63"
      updated.title.should == "Bar Bar"
      updated.data.should == {}
      updated.edit_uri.should == URI("https://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/3f93e3738e811d63")
    end

    it "deletes an existing one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new(Nori.parse(File.read("spec/responses/groups/update.xml"))["entry"])

      mock_response(File.read("spec/responses/groups/update.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request) do |request|
          request.path.should == "/m8/feeds/groups/default/base/3f93e3738e811d63"
          request.to_hash["if-match"].should == [element.etag]
          request.to_hash["authorization"].should == ["Bearer 12341234"]

          res_mock
        end
      end

      client.delete!(element)
    end

    it "batch creates without an error" do
      Time.any_instance.stub(:iso8601).and_return("2012-04-06T06:02:04Z")

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)

      element = GContacts::Element.new
      element.title = "foo bar"
      element.content = "Bar Foo"
      element.category = "group"
      element.create

      mock_response(File.read("spec/responses/groups/batch_success.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_post) do |uri, data, headers|
          uri.should == "/m8/feeds/groups/default/full/batch"
          headers.should include("Authorization" => "Bearer 12341234")

          Nori.parse(data).should == {"feed" => {"atom:entry" => {"batch:id" => "create", "batch:operation" => {"@type" => "insert"}, "atom:category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#group"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "atom:content" => "Bar Foo", "atom:title" => "foo bar", "@xmlns:atom" => "http://www.w3.org/2005/Atom", "@xmlns:gd" => "http://schemas.google.com/g/2005"}, "@xmlns" => "http://www.w3.org/2005/Atom", "@xmlns:gContact" => "http://schemas.google.com/contact/2008", "@xmlns:gd" => "http://schemas.google.com/g/2005", "@xmlns:batch" => "http://schemas.google.com/gdata/batch"}}

          res_mock
        end
      end

      results = client.batch!([element])
      results.should have(1).item
      result = results.first
      result.data.should == {}
      result.batch.should == {"status" => "create", "code" => "201", "reason" => "Created", "operation" => "insert"}
    end

    it "batch creates with an error" do
      Time.any_instance.stub(:iso8601).and_return("2012-04-06T06:02:04Z")

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)

      element = GContacts::Element.new
      element.category = "group"
      element.create

      mock_response(File.read("spec/responses/groups/batch_error.xml")) do |http_mock, res_mock|
        http_mock.should_receive(:request_post) do |uri, data, headers|
          uri.should == "/m8/feeds/groups/default/full/batch"
          headers.should include("Authorization" => "Bearer 12341234")

          Nori.parse(data).should == {"feed" => {"atom:entry" => {"batch:id" => "create", "batch:operation" => {"@type" => "insert"}, "atom:category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#group"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "atom:content" => {"@type" => "text"}, "atom:title" => nil, "@xmlns:atom" => "http://www.w3.org/2005/Atom", "@xmlns:gd" => "http://schemas.google.com/g/2005"}, "@xmlns" => "http://www.w3.org/2005/Atom", "@xmlns:gContact" => "http://schemas.google.com/contact/2008", "@xmlns:gd" => "http://schemas.google.com/g/2005", "@xmlns:batch" => "http://schemas.google.com/gdata/batch"}}

          res_mock
        end
      end

      results = client.batch!([element])
      results.should have(1).item
      result = results.first
      result.data.should == {}
      result.batch.should == {"status" => "create", "code" => "400", "reason" => "Entry does not have any fields set", "operation" => "insert"}
    end
  end
end
