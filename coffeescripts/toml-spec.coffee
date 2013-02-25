describe "TOML", ->
  it "should handle an empty string", ->
    expect(TOML.parse("")).toEqual({})
  
  it "should handle a simple key value assignment", ->
    expect(TOML.parse('title = "TOML Example"')).toEqual({title: "TOML Example"})
  
  it "should handle two lines with key value assignments", ->
    expect(TOML.parse('a = "A"\nb = "B"')).toEqual({a: 'A', b: 'B'})

  it "should handle quoted strings", ->
    expect(TOML.parse('a = "a \\"quoted\\" string"')).toEqual({a: 'a "quoted" string'})
  
  it "should handle escaped newlines", ->
    expect(TOML.parse('bio = "GitHub Cofounder & CEO\\nLikes tater tots and beer."')).toEqual({bio: "GitHub Cofounder & CEO\nLikes tater tots and beer."})

  it "should handle a key group", ->
    expect(TOML.parse('[group]\na = "A"\nb = "B"')).toEqual({group: {a: "A", b: "B"}})
  
  it "should handle conscutive key groups", ->
    expect(TOML.parse('[group]\na = "A"\nb = "B"\n[another]\nc = "C"\nd = "D"')).toEqual({group: {a: "A", b: "B"}, another: {c: "C", d: "D"}})
  
  it "should handle nested key groups", ->
    result = TOML.parse('[first]\na = "A"\nb = "B"\n  [second]\n  c = "C"\n  d = "D"')
    expect(result).toEqual({first: {a: "A", b: "B", second: {c: "C", d: "D"}}})
  
  it "should handle keygroups with . separators", ->
    expect(TOML.parse('[a.b]\nc = "C"\n[a.d]\ne = "E"')).toEqual({a: {b: {c: "C"}, d: {e: "E"}}})
  
  it "should handle integers", ->
    expect(TOML.parse('a = 1')).toEqual({a: 1})

  it "should handle negative integers", ->
    expect(TOML.parse('a = -1')).toEqual({a: -1})
    
  it "should handle floats", ->
    expect(TOML.parse('a = 1.2')).toEqual({a: 1.2})

  it "should handle negative floats", ->
    expect(TOML.parse('a = -1.2')).toEqual({a: -1.2})
  
  it "should handle booleans", ->
    expect(TOML.parse('a = true\nb = false')).toEqual({a: true, b: false})
  
  it "should handle dates", ->
    result = TOML.parse('date = 1979-05-27T07:32:00Z')
    expect(result.date.getFullYear()).toEqual(1979)
  
  it "should handle arrays", ->
    expect(TOML.parse('a = [1,2,3]')).toEqual({a: [1,2,3]})
  
  it "should handle nested arrays", ->
    expect(TOML.parse('a = [[1,2],[3,4]]')).toEqual({a: [[1,2],[3,4]]})

  it "should handle nested arrays with strings and integers", ->
    expect(TOML.parse('data = [ ["gamma", "delta"], [1, 2] ] # just an update to make sure parsers support it'))
      .toEqual({data: [["gamma", "delta"], [1,2]]})
    
  it "should handle comments", ->
    result = TOML.parse('# A comment\n\na = 1 # one\n[b] # comment\nc = [ # test\n1, # array\n2 # comments\n]')
    expect(result).toEqual({a: 1, b: {c: [1,2]}})
    