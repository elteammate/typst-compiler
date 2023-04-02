#import "typesystem-lexer.typ": *
#import "typesystem-def.typ": *
#let typesystem_parse = {
    (tokens) => {
    let token_mapping = if type(ts_token_kind.punc_colon) == "string" {let res = (:); res.insert(ts_token_kind.punc_colon, 0); res.insert(ts_token_kind.ty_array, 1); res.insert(ts_token_kind.ident, 2); res.insert(ts_token_kind.ty_bool, 3); res.insert(ts_token_kind.punc_gt, 4); res.insert(ts_token_kind.ty_int, 5); res.insert(ts_token_kind.ty_arguments, 6); res.insert(ts_token_kind.punc_comma, 7); res.insert(ts_token_kind.ty_none_, 8); res.insert(ts_token_kind.ty_content, 9); res.insert(ts_token_kind.ty_object, 10); res.insert(ts_token_kind.ty_dictionary, 11); res.insert(ts_token_kind.ty_any, 12); res.insert(ts_token_kind.ty_tuple, 13); res.insert(ts_token_kind.alias, 14); res.insert(ts_token_kind.punc_lt, 15); res.insert(ts_token_kind.ty_string, 16); res.insert(ts_token_kind.ty_float, 17); res.insert(ts_token_kind.ty_function, 18);  res} else {let res = range(ts_token_kind.len()); res.at(ts_token_kind.punc_colon) = 0; res.at(ts_token_kind.ty_array) = 1; res.at(ts_token_kind.ident) = 2; res.at(ts_token_kind.ty_bool) = 3; res.at(ts_token_kind.punc_gt) = 4; res.at(ts_token_kind.ty_int) = 5; res.at(ts_token_kind.ty_arguments) = 6; res.at(ts_token_kind.punc_comma) = 7; res.at(ts_token_kind.ty_none_) = 8; res.at(ts_token_kind.ty_content) = 9; res.at(ts_token_kind.ty_object) = 10; res.at(ts_token_kind.ty_dictionary) = 11; res.at(ts_token_kind.ty_any) = 12; res.at(ts_token_kind.ty_tuple) = 13; res.at(ts_token_kind.alias) = 14; res.at(ts_token_kind.punc_lt) = 15; res.at(ts_token_kind.ty_string) = 16; res.at(ts_token_kind.ty_float) = 17; res.at(ts_token_kind.ty_function) = 18;  res}
    let callbacks = (((o,_0,ts,_2)=>mk_type(o,..ts)),((t,_0,ts,_2)=>mk_type(t,..ts)),((f,_0,ret,_1,ts,_2)=>mk_type(f,ret,..ts)),(a => a),((i)=>"any"),(a => a),(a => a),((n,_,t)=>((name:n,ty:t),)),(a => a),((ts,_,t)=>ts+(t,)),((i)=>"tuple"),(()=>()),(a => a),((i)=>"object"),((i)=>"array"),((i)=>"arguments"),((i)=>"none"),((i)=>"float"),((ts,_,n,_1,t)=>ts+((name:n,ty:t),)),(a => a),((d,_1,t,_2)=>mk_type(d,t)),((i)=>"bool"),((i)=>"int"),((i)=>"content"),(a => a),((i)=>"function"),((t)=>(t,)),((a)=>panic("Not implemented (type alias resolution)")),((i)=>i),(a => a),((a,_1,t,_2)=>mk_type(a,t)),((i)=>"string"),(()=>()),(a => a),((i)=>"dictionary"),)
    let table = ((0,11,0,8,0,6,9,0,2,3,14,10,7,13,15,0,4,5,12,0,0,1,0,0,0,),(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,57,0,0,0,0,0,),(0,0,0,0,-23,0,0,-23,0,0,0,0,0,0,0,0,0,0,0,-23,0,0,0,0,0,),(0,0,0,0,-27,0,0,-27,0,0,0,0,0,0,0,0,0,0,0,-27,0,0,0,0,0,),(0,0,0,0,-30,0,0,-30,0,0,0,0,0,0,0,0,0,0,0,-30,0,0,0,0,0,),(0,0,0,0,-29,0,0,-29,0,0,0,0,0,0,0,0,0,0,0,-29,0,0,0,0,0,),(0,0,0,0,-2,0,0,-2,0,0,0,0,0,0,0,0,0,0,0,-2,0,0,0,0,0,),(0,0,0,0,-16,0,0,-16,0,0,0,0,0,0,0,0,0,0,0,-16,0,0,0,0,0,),(0,0,0,0,-32,0,0,-32,0,0,0,0,0,0,0,0,0,0,0,-32,0,0,0,0,0,),(0,0,0,0,-6,0,0,-6,0,0,0,0,0,0,0,0,0,0,0,-6,0,0,0,0,0,),(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,54,0,0,0,0,0,0,0,0,0,),(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,51,0,0,0,0,0,0,0,0,0,),(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,46,0,0,0,0,0,0,0,0,0,),(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,40,0,0,0,0,0,0,0,0,0,),(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,16,0,0,0,0,0,0,0,0,0,),(0,0,0,0,-8,0,0,-8,0,0,0,0,0,0,0,0,0,0,0,-8,0,0,0,0,0,),(0,30,19,26,-3,24,27,-3,20,21,32,28,25,31,0,0,22,23,29,0,18,0,17,0,0,),(0,0,0,0,35,0,0,36,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(33,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-19,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-12,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-18,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-13,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-14,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-21,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-25,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(-22,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(0,11,0,8,0,6,9,0,2,3,14,10,7,13,15,0,4,5,12,0,0,34,0,0,0,),(0,0,0,0,-28,0,0,-28,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(0,0,0,0,-35,0,0,-35,0,0,0,0,0,0,0,0,0,0,0,-35,0,0,0,0,0,),(0,0,37,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(38,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(0,11,0,8,0,6,9,0,2,3,14,10,7,13,15,0,4,5,12,0,0,39,0,0,0,),(0,0,0,0,-17,0,0,-17,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(0,11,0,8,-24,6,9,-24,2,3,14,10,7,13,15,0,4,5,12,0,0,42,0,41,0,),(0,0,0,0,43,0,0,44,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(0,0,0,0,-9,0,0,-9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(0,0,0,0,-34,0,0,-34,0,0,0,0,0,0,0,0,0,0,0,-34,0,0,0,0,0,),(0,11,0,8,0,6,9,0,2,3,14,10,7,13,15,0,4,5,12,0,0,45,0,0,0,),(0,0,0,0,-26,0,0,-26,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(0,11,0,8,0,6,9,0,2,3,14,10,7,13,15,0,4,5,12,0,0,47,0,0,0,),(0,0,0,0,0,0,0,48,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(0,11,0,8,-24,6,9,-24,2,3,14,10,7,13,15,0,4,5,12,0,0,42,0,49,0,),(0,0,0,0,50,0,0,44,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(0,0,0,0,-33,0,0,-33,0,0,0,0,0,0,0,0,0,0,0,-33,0,0,0,0,0,),(0,11,0,8,0,6,9,0,2,3,14,10,7,13,15,0,4,5,12,0,0,52,0,0,0,),(0,0,0,0,53,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(0,0,0,0,-5,0,0,-5,0,0,0,0,0,0,0,0,0,0,0,-5,0,0,0,0,0,),(0,11,0,8,0,6,9,0,2,3,14,10,7,13,15,0,4,5,12,0,0,55,0,0,0,),(0,0,0,0,56,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,),(0,0,0,0,-15,0,0,-15,0,0,0,0,0,0,0,0,0,0,0,-15,0,0,0,0,0,))
    let arg_count = (4,4,6,1,1,1,1,3,1,3,1,0,1,1,1,1,1,1,5,1,4,1,1,1,1,1,1,1,1,1,4,1,0,1,1,)
    let goto_index = (21,21,21,21,20,21,21,22,21,23,20,23,21,20,20,20,20,20,22,21,21,20,20,20,24,20,23,21,20,21,21,20,22,21,20,)
    let cast_table = (_ => none,_=>ptype.array,x=>x.text,_=>types.bool,_ => none,_=>types.int,_=>types.arguments,_ => none,_=>types.none_,_=>types.content,_=>ptype.object,_=>ptype.dictionary,_=>types.any,_=>ptype.tuple,x=>x.text,_ => none,_=>types.string,_=>types.float,_=>ptype.function,)
    let stack = (0, )
    let ast_stack = ()
    let cur_token = 0
    for i in range(9999) { for j in range(9999) {
        let state = stack.last()
        let terminal = if cur_token < tokens.len() {
            token_mapping.at(tokens.at(cur_token).kind)
        } else {
            19
        }
        let action = table.at(state).at(terminal)
        if action == 57 {
            assert(ast_stack.len() == 1)
            return ast_stack.first()
        } else if action > 0 {
            stack.push(action)
            ast_stack.push(cast_table.at(terminal)(tokens.at(cur_token)))
            cur_token += 1
        } else if action < 0 {
            let rhs = ()
            for _ in range(arg_count.at(action)) {
                let _ = stack.pop()
                rhs.push(ast_stack.pop())
            }
            let rule = callbacks.at(action)
            ast_stack.push(rule(..rhs.rev()))
            let goto_state = table.at(stack.last()).at(goto_index.at(action))
            if goto_state > 0 {
                stack.push(goto_state)
            } else {
                panic("Expected shift action")
            }
        } else {
            panic("Parsing error at state: " + repr(stack) + " and token: " +
                repr(if cur_token < tokens.len() { tokens.at(cur_token) } else {"EOF"})
                + " at: " + repr(cur_token)
            )
        }
    } }
    panic("too complex")
}
}