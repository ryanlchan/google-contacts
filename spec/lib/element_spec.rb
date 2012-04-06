require "spec_helper"

describe GContacts::Element do
  before :all do
    Nori.parser = :nokogiri
  end

  it "changes modifier flags" do
    element = GContacts::Element.new

    element.create
    element.modifier_flag.should == :create

    element.delete
    element.modifier_flag.should == nil

    element.instance_variable_set(:@edit_uri, URI("http://google.com"))
    element.update
    element.modifier_flag.should == :update

    element.delete
    element.modifier_flag.should == :delete
  end

  context "converts back to xml" do
    before :each do
      Time.any_instance.stub(:iso8601).and_return("2012-04-06T06:02:04Z")
    end

    it "with deleting an entry" do
      element = GContacts::Element.new(Nori.parse(File.read("spec/responses/contacts/get.xml"))["entry"])
      element.delete

      Nori.parse(element.to_xml).should == {"entry" => {"id" => "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8", "@gd:etag" => "YzllYTBkNmQwOWRlZGY1YWEyYWI5."}}
      Nori.parse(element.to_xml(true)).should == {"entry" => {"batch:id" => "delete", "batch:operation" => {"@type" => "delete"}, "id" => "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8", "@gd:etag" => "YzllYTBkNmQwOWRlZGY1YWEyYWI5."}}
    end

    it "with creating an entry" do
      element = GContacts::Element.new
      element.category = "contact"
      element.content = "Foo Content"
      element.title = "Foo Title"
      element.data = {"gd:name" => {"gd:fullName" => "John Doe", "gd:givenName" => "John", "gd:familyName" => "Doe"}}
      element.create

      Nori.parse(element.to_xml).should == {"entry" => {"category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "content" => "Foo Content", "title" => "Foo Title", "gd:name" => {"gd:fullName" => "John Doe", "gd:givenName" => "John", "gd:familyName" => "Doe"}}}
      Nori.parse(element.to_xml(true)).should == {"entry" => {"batch:id" => "create", "batch:operation" => {"@type" => "create"}, "category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "content" => "Foo Content", "title" => "Foo Title", "gd:name" => {"gd:fullName" => "John Doe", "gd:givenName" => "John", "gd:familyName" => "Doe"}}}
    end

    it "updating an entry in batch" do
      element = GContacts::Element.new(Nori.parse(File.read("spec/responses/contacts/get.xml"))["entry"])
      element.update

      Nori.parse(element.to_xml).should == {"entry" => {"id" => "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8", "category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "content" => {"@type" => "text"}, "title" => "Casey", "gd:name" => {"gd:fullName" => "Casey", "gd:givenName" => "Casey"}, "gd:email" => {"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "casey@gmail.com", "@primary" => "true"}, "@gd:etag" => "YzllYTBkNmQwOWRlZGY1YWEyYWI5."}}
      Nori.parse(element.to_xml(true)).should == {"entry" => {"batch:id" => "update", "batch:operation" => {"@type" => "update"}, "id" => "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8", "category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "content" => {"@type" => "text"}, "title" => "Casey", "gd:name" => {"gd:fullName" => "Casey", "gd:givenName" => "Casey"}, "gd:email" => {"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "casey@gmail.com", "@primary" => "true"}, "@gd:etag" => "YzllYTBkNmQwOWRlZGY1YWEyYWI5."}}
    end

    it "with contacts" do
      elements = GContacts::List.new(Nori.parse(File.read("spec/responses/contacts/all.xml")))

      expected = [
        {"entry" => {"id" => "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/fd8fb1a55f2916e", "category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "content" => {"@type" => "text"}, "title" => "Steve Stephson", "gd:name" => {"gd:fullName" => "Steve Stephson", "gd:givenName" => "Steve", "gd:familyName" => "Stephson"}, "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve.stephson@gmail.com", "@primary" => "true"}, {"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve@gmail.com"}], "gd:phoneNumber" => ["3005004000", "+130020003000"], "@gd:etag" => "OWUxNWM4MTEzZjEyZTVjZTQ1Mjgy."}},
        {"entry" => {"id" => "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/894bc75ebb5187d", "category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "content" => {"@type" => "text"}, "title" => "Jill Doe", "gd:name" => {"gd:fullName" => "Jill Doe", "gd:givenName" => "Jill", "gd:familyName" => "Doe"}, "@gd:etag" => "ZGRhYjVhMTNkMmFhNzJjMzEyY2Ux."}},
        {"entry" => {"id" => "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/cd046ed518f0fb0", "category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "content" => {"@type" => "text"}, "title" => "Dave \"Terry\" Pratchett", "gd:name" => {"gd:fullName" => "Dave \"Terry\" Pratchett", "gd:givenName" => "Dave", "gd:additionalName" => "\"Terry\"", "gd:familyName" => "Pratchett"}, "gd:organization" => {"gd:orgName" => "Foo Bar Inc", "@rel" => "http://schemas.google.com/g/2005#work"}, "gd:email" => {"@rel" => "http://schemas.google.com/g/2005#home", "@address" => "dave.pratchett@gmail.com", "@primary" => "true"}, "gd:phoneNumber" => "7003002000", "@gd:etag" => "ZWVhMDQ0MWI0MWM0YTJkM2MzY2Zh."}},
        {"entry" => {"id" => "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/a1941d3d13cdc66", "category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "content" => {"@type" => "text"}, "title" => "Jane Doe", "gd:name" => {"gd:fullName" => "Jane Doe", "gd:givenName" => "Jane", "gd:familyName" => "Doe"}, "gd:email" => {"@rel" => "http://schemas.google.com/g/2005#home", "@address" => "jane.doe@gmail.com", "@primary" => "true"}, "gd:phoneNumber" => "16004003000", "gd:structuredPostalAddress" => {"gd:formattedAddress" => "5 Market St\n        San Francisco\n        CA\n      ", "gd:street" => "5 Market St", "gd:city" => "San Francisco", "gd:region" => "CA", "@rel" => "http://schemas.google.com/g/2005#home"}, "@gd:etag" => "Yzg3MTNiODJlMTRlZjZjN2EyOGRm."}}
      ]

      elements.each do |element|
        element.category.should == "contact"
        Nori.parse(element.to_xml).should == expected.shift
      end

      expected.should have(0).items
    end

    it "with groups" do
      elements = GContacts::List.new(Nori.parse(File.read("spec/responses/groups/all.xml")))

      expected = [
          {"entry" => {"id" => "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6", "category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#group"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "content" => {"@type" => "text"}, "title" => "System Group: My Contacts", "@gd:etag" => "YWJmYzA."}},
          {"entry" => {"id" => "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/ada43d293fdb9b1", "category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#group"}, "updated" => DateTime.parse("2012-04-06T06:02:04Z"), "content" => {"@type" => "text"}, "title" => "Misc", "@gd:etag" => "QXc8cDVSLyt7I2A9WxNTFUkLRQQ."}}
      ]
          
      elements.each do |element|
        element.category.should == "group"
        Nori.parse(element.to_xml).should == expected.shift
      end

      expected.should have(0).items
    end
  end
end