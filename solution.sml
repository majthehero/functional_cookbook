exception NotImplemented

exception ElementNotInDict

structure Dictionary :> DICTIONARY =
struct
    type (''key, 'value) dict = (''key * 'value) list

    val empty = []

    fun exists dict key = 
        case dict of nil => false
        | (k, v)::t => k = key orelse exists t key;

    fun isEmpty dict = 
        case dict of nil => true
        | _ => false;

    fun size dict = 
        let 
            fun size_tl (dict, acc) =
                case dict of nil => acc
                | h::t => size_tl (t, acc+1);
        in
            size_tl (dict, 0)
        end;

    fun get dict key = 
        let
            val entry = List.find (fn (k, v) => k = key) dict
        in
            if isSome entry 
            then SOME (#2 (valOf entry))
            else NONE
        end;

    fun getOrDefault dict key default = 
        let 
            val entry = get dict key
        in
            if isSome entry then valOf entry
            else default 
        end;

    fun set dict key value = 
        if exists dict key
        then map 
            (fn (k,v) => if k = key then (k,value) else (k,v)) dict
        else (key, value) :: dict;

    fun remove dict key = 
        if exists dict key then raise ElementNotInDict
        else List.foldr
            (fn ((k,v), acc) => if k = key then acc else (k,v)::acc)
            nil dict;

    fun keys dict = 
        map (fn (k,v) => k) dict;

    fun values dict = 
        map (fn (k,v) => v) dict;

    fun toList dict = 
        dict;

    fun fromList list = 
            List.foldr 
                (fn ((k, v), acc) => set acc k v) 
                empty list;

    fun merge a dict = 
        case dict of nil => a
        | ((k,v)::t) => merge (set dict k v) t;

    fun filter f dict = 
        case dict of nil => nil
        | ((k,v)::t) => 
            if f(k,v) then (k,v)::(filter f t)
            else filter f t;

    fun map f dict = 
        case dict of nil => nil
        | ((k,v)::t) => (f(k,v))::(map f t);
end

structure Cookbook :> COOKBOOK =
struct
    type ingredient = string
    type stock = (ingredient, int) Dictionary.dict
    type pricelist = (ingredient, real) Dictionary.dict
    type recipe = ingredient * stock
    type cookbook = (ingredient, stock) Dictionary.dict

    exception NoPriceException

    fun makeIngredient name = 
        name;

    fun makeStock ingredients = 
        Dictionary.fromList ingredients;

    fun makePricelist pricelist = 
        Dictionary.fromList pricelist;

    fun makeRecipe recipe = 
        recipe;

    fun makeCookbook recipes = 
        Dictionary.fromList recipes;

    fun ingredientToString ingredient = 
        ingredient;

    (* util : TODO: move to some util thing somewhere *)
    fun str_qsort (lst, f_cmp:string*string->order) =
                case lst of nil => lst
                | [x] => [x]
                | _ =>
                    let
                        val mid_key = #1 (hd lst)
                        val lower = List.filter 
                            (fn (key,_) => f_cmp(key,mid_key) = LESS)
                            lst;
                        val upper = List.filter 
                            (fn (key,_) => f_cmp(key,mid_key) <> LESS)
                            lst;
                    in
                        str_qsort(lower, f_cmp) @ str_qsort(upper, f_cmp)
                    end;

    fun stockToString stock = 
        let 
            val sorted = str_qsort (Dictionary.toList(stock), String.compare)
            val text = List.foldr 
                            (fn ((ing, x), pre_text) => 
                                if x > 0 
                                then pre_text ^ ing ^ ": " ^ (Int.toString x) ^ "\n"
                                else pre_text) 
                            "" sorted
        in
            (print text; text)
        end;

    fun pricelistToString pricelist = 
        let 
            val sorted = str_qsort (Dictionary.toList(pricelist), String.compare)
            val text = List.foldr
                (fn ((ing, prc), pre_text) =>
                    pre_text ^ ing ^ ": " ^ (Real.toString prc) ^ "\n") 
                    "" sorted
        in
            (print text; text)
        end;

    fun recipeToString recipe = 
        let
            val (rec_name, rec_stock) = recipe
            val title = "=== " ^ rec_name ^ " ==="
        in
            (print title; title ^ stockToString(rec_stock))
        end;

    fun cookbookToString cookbook = 
        let val sorted = str_qsort(Dictionary.toList(cookbook), String.compare)
        in List.foldl (fn (r, acc) => recipeToString(r) ^ acc) "" sorted
        end;

    fun hasEnoughIngredients stock recipe = 
        let
            val (_, required) = recipe 
        in
            List.foldr (fn (b, acc) => b andalso acc) true
            (map
                (fn (ing_name, ing_num) => 
                    Dictionary.exists stock ing_name andalso 
                    (valOf (Dictionary.get stock ing_name)) >= ing_num)
                (Dictionary.toList required) )
        end;

    fun cook recipe stock = 
        let
            val (dish, required) = recipe
        in
            (Dictionary.set (
                Dictionary.map (
                fn (ing, num) => 
                   (ing, num - (Dictionary.getOrDefault required ing 0))
            ) stock) dish 1 )
        end;
        
    fun priceOfStock stock pricelist = 
        List.foldr (
            fn ((ing, num), acc) => 
                if not (Dictionary.exists pricelist ing) then raise NoPriceException
                else (Dictionary.getOrDefault pricelist ing 0.0) * (Real.fromInt num) + acc
        ) 0.0 (Dictionary.toList stock);

    fun priceOfRecipe recipe pricelist = 
        let
            val (dish, required) = recipe
        in
            priceOfStock required pricelist
        end;

    fun missingIngredients recipe stock = 
        let
            val (dish, required) = recipe
        in
            Dictionary.filter (
                fn (ing, num) => 
                (not (Dictionary.exists stock ing)) orelse
                (Dictionary.getOrDefault stock ing 0) < num
            ) required
        end;

    fun possibleRecipes cookbook stock = 
        Dictionary.filter (
            fn (ing, required) => 
                Dictionary.isEmpty
                    (missingIngredients (ing, required) stock)
        ) cookbook;

    fun generateVariants recipe substitutions = 
        

    fun cheapestRecipe cookbook pricelist = 
        List.foldl
            (
                fn (recipe, acc) =>
                    let
                        val price = priceOfRecipe recipe pricelist
                    in
                        if not(isSome acc) orelse (priceOfRecipe (valOf acc) pricelist) > price
                        then SOME recipe
                        else acc
                    end
            ) NONE (Dictionary.toList cookbook)
end
