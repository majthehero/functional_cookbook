exception NotImplemented

fun str_qsort (lst: (string * 'a) list) : (string * 'a) list =
    case lst of [] => nil
    | [(s,n)] => [(s,n)]
    | (s1, n2)::ostalo => 
    str_qsort(
        List.filter (fn (s, n) => s <= s1) ostalo
    ) @ [(s1,n2)] @ str_qsort(
        List.filter (fn (s, n) => s > s1) ostalo
    );
    

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
        if not (exists dict key) then dict
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


    fun stockToString stock = 
        let 
            val sorted = str_qsort (Dictionary.toList stock)
            val text = List.foldl 
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
            val sorted = str_qsort (Dictionary.toList pricelist)
            val text = List.foldl
                (fn ((ing, prc), pre_text) =>
                    pre_text ^ ing ^ ": " ^ (Real.toString prc) ^ "\n") 
                    "" sorted
        in
            (print text; text)
        end;

    fun recipeToString recipe = 
        let
            val (rec_name, rec_stock) = recipe
            val title = "=== " ^ rec_name ^ " ===\n"
        in
            (print title; title ^ stockToString(rec_stock))
        end;

    fun cookbookToString cookbook = 
        let val sorted = str_qsort (Dictionary.toList cookbook)
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

    fun generateVariants recipe substitutions = makeCookbook [recipe] (* ni ratal *)
    (* fun generateVariants recipe substitutions = 
        let
            val (dish, req) = recipe
            fun mutate_recipe (recipe, subst) =
                let
                    val generated =
                        List.tabulate (List.length subst,
                            fn i => 
                            let
                                val (rec_name, rec_req) = recipe
                                val new_ing = List.nth (subst, i)
                                val old_ing = List.find (
                                    fn some_ing => Dictionary.exists rec_req some_ing
                                ) subst (* OPTION *)
                                val old_num = if isSome old_ing then Dictionary.get rec_req (valOf old_ing) (* OPTION *)
                                                else NONE
                            in
                                case old_ing of NONE => NONE
                                | _ =>
                                    SOME(rec_name, Dictionary.set (Dictionary.remove rec_name (valOf old_ing)) new_ing (valOf old_num))
                            end)
                    val generated_fixed = Dictionary.fromList (List.filter (fn el => isSome el) generated)
                in
                    case generated_fixed of NONE => Dictionary.empty
                    | _ => Dictionary.fromList (valOf generated_fixed)
                end
        in
            List.foldl ( 
                fn (subst, acc) =>
                    let val new_recepies = mutate_recipe(recipe, subst)
                in
                    case new_recepies of NONE => acc
                    | _ => Dictionary.merge acc new_recepies
                end
            ) (Dictionary.set Dictionary.empty dish req) substitutions
        end; *)

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
