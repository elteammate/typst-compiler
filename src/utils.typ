#let mk_enum(debug: false, name: none, ..options) = {
  let result = (:)

  for i, v in options.pos() {
    if debug {
      if name == none {
        result.insert(v, v)
      } else {
        result.insert(v, name + "." + v)
      }
    } else {
      result.insert(v, i)
    }
  }

  result
}

#let unique(arr) = {
  let dict = (:)
  for x in arr { dict.insert(repr(x), x) }
  dict.values()
}

#let map2(f, arr) = {
  let result = ()
  for i, x in arr { result.push(f(i, x)) }
  result
}

#let arr2dict(arr) = {
  let result = (:)
  for x in arr { result.insert(x.at(0), x.at(1)) }
  result
}

#let dict2arr(dict) = {
  let result = ()
  for k, v in dict { result.push((k, v)) }
  result
}

#let dict_map(keys, f) = {
  let result = (:)
  for k in keys { result.insert(k, f(k)) }
  return result
}
