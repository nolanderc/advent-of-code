use std::collections::{HashMap, HashSet};
use std::io::Read;

fn main() {
    let mut input = String::new();
    std::io::stdin().read_to_string(&mut input).unwrap();

    let mut foods = Vec::new();
    for line in input.trim().lines() {
        let (ingredients, allergens) = line.split_at(line.find('(').unwrap());
        let ingredients = ingredients.split_whitespace().collect();
        let allergens = allergens
            .trim_start_matches("(contains ")
            .trim_end_matches(')')
            .split(", ")
            .collect();
        foods.push(Food {
            ingredients,
            allergens,
        });
    }

    // all possible ingredients
    let mut ingredients = HashSet::new();
    for food in foods.iter() {
        ingredients.extend(food.ingredients.iter().copied());
    }

    // for each allergen, the possible ingredients that contain that allergen.
    let mut allergens = HashMap::new();
    for food in foods.iter() {
        for &allergen in food.allergens.iter() {
            let poss = allergens
                .entry(allergen)
                .or_insert_with(|| food.ingredients.clone());
            *poss = std::mem::take(poss)
                .intersection(&food.ingredients)
                .copied()
                .collect();
        }
    }

    // for each ingredient, the possible allergens it could contain
    let mut ingredient_allergens = HashMap::new();
    for (&allergen, ingredients) in allergens.iter() {
        for &ingredient in ingredients.iter() {
            ingredient_allergens
                .entry(ingredient)
                .or_insert_with(HashSet::new)
                .insert(allergen);
        }
    }

    let part1 = foods
        .iter()
        .flat_map(|food| food.ingredients.iter().copied())
        .filter(|ingredient| !ingredient_allergens.contains_key(ingredient))
        .count();

    let mut assignments = Vec::new();
    while assignments.len() < allergens.len() {
        let (&ingredient, allergens) = ingredient_allergens
            .iter()
            .find(|(_, allergens)| allergens.len() == 1)
            .unwrap();
        let &allergen = allergens.iter().next().unwrap();
        assignments.push((allergen, ingredient));

        for allergens in ingredient_allergens.values_mut() {
            allergens.remove(allergen);
        }
    }

    assignments.sort();
    let ingredients = assignments
        .into_iter()
        .map(|(_, ingredient)| ingredient)
        .collect::<Vec<_>>();

    let canonical_dangerous_ingredient_list = ingredients.join(",");

    println!("part1: {}", part1);
    println!("part2: {}", canonical_dangerous_ingredient_list);
}

struct Food<'a> {
    ingredients: HashSet<&'a str>,
    allergens: HashSet<&'a str>,
}
