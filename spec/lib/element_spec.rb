require "spec_helper"

describe GContacts::Element do
  let(:parser) { Nori.new }

  it "changes modifier flags" do
    element = GContacts::Element.new

    element.create
    element.modifier_flag.should == :create

    element.delete
    element.modifier_flag.should == nil

    element.instance_variable_set(:@id, URI("http://google.com/a/b/c"))
    element.update
    element.modifier_flag.should == :update

    element.delete
    element.modifier_flag.should == :delete
  end

  context "converts back to xml" do
    before :each do
      Time.any_instance.stub(:iso8601).and_return("2012-04-06T06:02:04Z")
    end

    it "with batch used" do
      element = GContacts::Element.new

      element.create
      xml = element.to_xml(true)
      xml.should =~ %r{<batch:id>create</batch:id>}
      xml.should =~ %r{<batch:operation type='insert'/>}

      element.instance_variable_set(:@id, URI("http://google.com/a/b/c"))
      element.update

      xml = element.to_xml(true)
      xml.should =~ %r{<batch:id>update</batch:id>}
      xml.should =~ %r{<batch:operation type='update'/>}

      element.delete
      xml = element.to_xml(true)
      xml.should =~ %r{<batch:id>delete</batch:id>}
      xml.should =~ %r{<batch:operation type='delete'/>}
    end

    it "with deleting an entry" do
      element = GContacts::Element.new(parser.parse(File.read("spec/responses/contacts/get.xml"))["entry"])
      element.delete

      parser.parse(element.to_xml).should == {"atom:entry" => {"id" => "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/3a203c8da7ac0a8", "@gd:etag" => '"YzllYTBkNmQwOWRlZGY1YWEyYWI5."', "@xmlns:atom" => "http://www.w3.org/2005/Atom", "@xmlns:gd" => "http://schemas.google.com/g/2005"}}
    end

    it "with creating an entry" do
      element = GContacts::Element.new
      element.category = "contact"
      element.content = "Foo Content"
      element.title = "Foo Title"
      element.data = {"gd:name" => {"gd:fullName" => "John Doe", "gd:givenName" => "John", "gd:familyName" => "Doe"}}
      element.create

      parser.parse(element.to_xml).should == {"atom:entry"=>{"atom:category"=>{"@scheme"=>"http://schemas.google.com/g/2005#kind", "@term"=>"http://schemas.google.com/g/2008#contact"}, "updated"=>DateTime.parse("2012-04-06T06:02:04+00:00"), "atom:content"=>"Foo Content", "atom:title"=>"Foo Title", "gd:name"=>{"gd:fullName"=>"John Doe", "gd:givenName"=>"John", "gd:familyName"=>"Doe"}, "@xmlns:atom"=>"http://www.w3.org/2005/Atom", "@xmlns:gd"=>"http://schemas.google.com/g/2005", "@xmlns:gContact"=>"http://schemas.google.com/contact/2008"}}
    end

    it "updating an entry" do
      element = GContacts::Element.new(parser.parse(File.read("spec/responses/contacts/get.xml"))["entry"])
      element.update

      parser.parse(element.to_xml).should == {"atom:entry"=>{"id"=>"http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/3a203c8da7ac0a8", "atom:category"=>{"@scheme"=>"http://schemas.google.com/g/2005#kind", "@term"=>"http://schemas.google.com/g/2008#contact"}, "updated"=>DateTime.parse("2012-04-06T06:02:04+00:00"), "atom:content"=>{"@type"=>"text"}, "atom:title"=>"Casey", "gd:name"=>{"gd:fullName"=>"Casey", "gd:givenName"=>"Casey"}, "gd:email"=>{"@rel"=>"http://schemas.google.com/g/2005#other", "@address"=>"casey@gmail.com", "@primary"=>"true"}, "@xmlns:atom"=>"http://www.w3.org/2005/Atom", "@xmlns:gd"=>"http://schemas.google.com/g/2005", "@xmlns:gContact"=>"http://schemas.google.com/contact/2008", "@gd:etag"=>"\"YzllYTBkNmQwOWRlZGY1YWEyYWI5.\""}}
    end

    it "updating an entry serialized and deserialized" do
      element = GContacts::Element.new(parser.parse(File.read("spec/responses/contacts/get.xml"))["entry"])
      element = YAML::load(YAML::dump(element))
      element.update

      parser.parse(element.to_xml).should == {"atom:entry"=>{"id"=>"http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/3a203c8da7ac0a8", "atom:category"=>{"@scheme"=>"http://schemas.google.com/g/2005#kind", "@term"=>"http://schemas.google.com/g/2008#contact"}, "updated"=>DateTime.parse("2012-04-06T06:02:04+00:00"), "atom:content"=>{"@type"=>"text"}, "atom:title"=>"Casey", "gd:name"=>{"gd:fullName"=>"Casey", "gd:givenName"=>"Casey"}, "gd:email"=>{"@rel"=>"http://schemas.google.com/g/2005#other", "@address"=>"casey@gmail.com", "@primary"=>"true"}, "@xmlns:atom"=>"http://www.w3.org/2005/Atom", "@xmlns:gd"=>"http://schemas.google.com/g/2005", "@xmlns:gContact"=>"http://schemas.google.com/contact/2008", "@gd:etag"=>"\"YzllYTBkNmQwOWRlZGY1YWEyYWI5.\""}}
    end

    it "with contacts" do
      elements = GContacts::List.new(parser.parse(File.read("spec/responses/contacts/all.xml")))

      expected = [
        {"id"=>"http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/fd8fb1a55f2916e", "atom:category"=>{"@scheme"=>"http://schemas.google.com/g/2005#kind", "@term"=>"http://schemas.google.com/g/2008#contact"}, "updated"=>DateTime.parse("2012-04-06T06:02:04+00:00"), "atom:content"=>{"@type"=>"text"}, "atom:title"=>"Steve Stephson", "gContact:groupMembershipInfo"=>[{"@deleted"=>"false", "@href"=>"http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"}, {"@deleted"=>"false", "@href"=>"http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"}], "gd:name"=>{"gd:fullName"=>"Steve Stephson", "gd:givenName"=>"Steve", "gd:familyName"=>"Stephson"}, "gd:email"=>[{"@rel"=>"http://schemas.google.com/g/2005#other", "@address"=>"steve.stephson@gmail.com", "@primary"=>"true"}, {"@rel"=>"http://schemas.google.com/g/2005#other", "@address"=>"steve@gmail.com"}], "gd:phoneNumber"=>["3005004000", "+130020003000"], "@xmlns:atom"=>"http://www.w3.org/2005/Atom", "@xmlns:gd"=>"http://schemas.google.com/g/2005", "@xmlns:gContact"=>"http://schemas.google.com/contact/2008", "@gd:etag"=>"\"OWUxNWM4MTEzZjEyZTVjZTQ1Mjgy.\""},

        {"id"=>"http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/894bc75ebb5187d", "atom:category"=>{"@scheme"=>"http://schemas.google.com/g/2005#kind", "@term"=>"http://schemas.google.com/g/2008#contact"}, "updated"=>DateTime.parse("2012-04-06T06:02:04+00:00"), "atom:content"=>{"@type"=>"text"}, "atom:title"=>"Jill Doe", "gd:name"=>{"gd:fullName"=>"Jill Doe", "gd:givenName"=>"Jill", "gd:familyName"=>"Doe"}, "@xmlns:atom"=>"http://www.w3.org/2005/Atom", "@xmlns:gd"=>"http://schemas.google.com/g/2005", "@xmlns:gContact"=>"http://schemas.google.com/contact/2008", "@gd:etag"=>"\"ZGRhYjVhMTNkMmFhNzJjMzEyY2Ux.\""},

        {"id"=>"http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/cd046ed518f0fb0", "atom:category"=>{"@scheme"=>"http://schemas.google.com/g/2005#kind", "@term"=>"http://schemas.google.com/g/2008#contact"}, "updated"=>DateTime.parse("2012-04-06T06:02:04+00:00"), "atom:content"=>{"@type"=>"text"}, "atom:title"=>"Dave \"Terry\" Pratchett", "gContact:groupMembershipInfo"=>[{"@deleted"=>"false", "@href"=>"http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"}, {"@deleted"=>"false", "@href"=>"http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"}], "gd:name"=>{"gd:fullName"=>"Dave \"Terry\" Pratchett", "gd:givenName"=>"Dave", "gd:additionalName"=>"\"Terry\"", "gd:familyName"=>"Pratchett"}, "gd:organization"=>{"gd:orgName"=>"Foo Bar Inc", "@rel"=>"http://schemas.google.com/g/2005#work"}, "gd:email"=>{"@rel"=>"http://schemas.google.com/g/2005#home", "@address"=>"dave.pratchett@gmail.com", "@primary"=>"true"}, "gd:phoneNumber"=>"7003002000", "@xmlns:atom"=>"http://www.w3.org/2005/Atom", "@xmlns:gd"=>"http://schemas.google.com/g/2005", "@xmlns:gContact"=>"http://schemas.google.com/contact/2008", "@gd:etag"=>"\"ZWVhMDQ0MWI0MWM0YTJkM2MzY2Zh.\""},

        {"id"=>"http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/a1941d3d13cdc66", "atom:category"=>{"@scheme"=>"http://schemas.google.com/g/2005#kind", "@term"=>"http://schemas.google.com/g/2008#contact"}, "updated"=>DateTime.parse("2012-04-06T06:02:04+00:00"), "atom:content"=>{"@type"=>"text"}, "atom:title"=>"Jane Doe", "gContact:groupMembershipInfo"=>[{"@deleted"=>"false", "@href"=>"http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"}, {"@deleted"=>"false", "@href"=>"http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"}], "gd:name"=>{"gd:fullName"=>"Jane Doe", "gd:givenName"=>"Jane", "gd:familyName"=>"Doe"}, "gd:email"=>{"@rel"=>"http://schemas.google.com/g/2005#home", "@address"=>"jane.doe@gmail.com", "@primary"=>"true"}, "gd:phoneNumber"=>"16004003000", "gd:structuredPostalAddress"=>{"gd:formattedAddress"=>"5 Market St\n        San Francisco\n        CA", "gd:street"=>"5 Market St", "gd:city"=>"San Francisco", "gd:region"=>"CA", "@rel"=>"http://schemas.google.com/g/2005#home"}, "@xmlns:atom"=>"http://www.w3.org/2005/Atom", "@xmlns:gd"=>"http://schemas.google.com/g/2005", "@xmlns:gContact"=>"http://schemas.google.com/contact/2008", "@gd:etag"=>"\"Yzg3MTNiODJlMTRlZjZjN2EyOGRm.\""}
      ]

      elements.each do |element|
        element.category.should == "contact"

        # The extra tags around this are to ensure the test works in JRuby which has a stricter parser
        # and requires the presence of the xlns:#### tags to properly extract data. This isn't an issue with LibXML.
        parser.parse("<feed xmlns='http://www.w3.org/2005/Atom' xmlns:gContact='http://schemas.google.com/contact/2008' xmlns:gd='http://schemas.google.com/g/2005' xmlns:batch='http://schemas.google.com/gdata/batch'>#{element.to_xml}</feed>")["feed"]["atom:entry"].should == expected.shift
      end

      expected.should have(0).items
    end

    it "with groups" do
      elements = GContacts::List.new(parser.parse(File.read("spec/responses/groups/all.xml")))

      expected = [
          {"atom:entry"=>{"id"=>"http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/full/6", "atom:category"=>{"@scheme"=>"http://schemas.google.com/g/2005#kind", "@term"=>"http://schemas.google.com/g/2008#group"}, "updated"=>DateTime.parse("2012-04-06T06:02:04+00:00"), "atom:content"=>"System Group: My Contacts", "atom:title"=>"System Group: My Contacts", "gContact:systemGroup"=>{"@id"=>"Contacts"}, "@xmlns:atom"=>"http://www.w3.org/2005/Atom", "@xmlns:gd"=>"http://schemas.google.com/g/2005", "@xmlns:gContact"=>"http://schemas.google.com/contact/2008", "@gd:etag"=>"\"YWJmYzA.\""}},

          {"atom:entry"=>{"id"=>"http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/full/ada43d293fdb9b1", "atom:category"=>{"@scheme"=>"http://schemas.google.com/g/2005#kind", "@term"=>"http://schemas.google.com/g/2008#group"}, "updated"=>DateTime.parse("2012-04-06T06:02:04+00:00"), "atom:content"=>"Misc", "atom:title"=>"Misc", "@xmlns:atom"=>"http://www.w3.org/2005/Atom", "@xmlns:gd"=>"http://schemas.google.com/g/2005", "@xmlns:gContact"=>"http://schemas.google.com/contact/2008", "@gd:etag"=>"\"QXc8cDVSLyt7I2A9WxNTFUkLRQQ.\""}}
      ]

      elements.each do |element|
        element.category.should == "group"
        parser.parse(element.to_xml).should == expected.shift
      end

      expected.should have(0).items
    end
  end
end
