/// Build a lexer with a given structure
///
/// The rules are represented by an array of pairs,
/// First element of each pair is a regular expression is used to
/// match tokens in the given source. Order of rules matters.
/// When extracting the token from source, the first rule is matched,
/// if match failed, then the second, and so on. Once a matching rule found,
/// The value from the second element of the pair is added to token list.
/// If no matching rule found, panics.
///
/// The second element also may be a function, in which case it would
/// be invoked with the match object as an argument. The returned value is
/// added to token list.
///
/// Finally, it can also be `none`, in which case the token is skipped.
///
/// The `post_process` callback is executed for every token in the generated 
/// list with a match object which matches the string at the given position.
/// It's usefult to add information after the tokenizer is finished, 
/// for example, about span of the token.
///
/// Sounds complicated, but it's super easy to use.
///
/// lexer: ((str, none | T | (match => T)))
/// post_process: (T, match) => any
#let compile_lexer(lexer, post_process) = {
  let full_regex = regex("((" + lexer.map(rule => rule.at(0)).join(")|(") + "))")
  let group_count_regex = regex("(^\(|[^\\\\]\()")
  
  let regex_group_mapping = ()
  let cur_group = 1

  for rule in lexer {
    regex_group_mapping.push((
      group_no: cur_group,
      rule: rule.at(1),
    ))
    cur_group += 1 + rule.at(0).matches(group_count_regex).len()
  }
  
  (s) => {
    let matches = s.matches(full_regex)
    for i, match in matches {
      if i + 1 < matches.len() {
        let next = matches.at(i + 1)
        if match.end != next.start {
          return (:).at("Slice `" + s.slice(match.end, next.start) + "` can not be lexed")
        }
      }
    }
    matches.map(match => {
      for rule_no, plausable_rule in regex_group_mapping {
        if match.captures.at(plausable_rule.group_no) == none { continue }
        
        let kind = if type(plausable_rule.rule) == "function" {
          (plausable_rule.rule)(match)
        } else if plausable_rule.rule == none {
          none
        } else {
          plausable_rule.rule
        }

        if kind == none { return none }

        match.captures = () => match.captures.slice(
          plausable_rule.group_no,
          if rule_no + 1 < regex_group_mapping.len() {
            regex_group_mapping.at(rule_no + 1).group_no
          } else {
            regex_group_mapping.len()
          }
        )
        
        return post_process(kind, match)
      }
    }).filter(x => x != none)
  }
}
