type ratio = {
  mass: float,
  energy: float,
  build_time: float,
};

let calculate = (base, compare_) => {
  let base_mass = float_of_int(max(base.UnitModel.build_cost_mass, 1));
  let base_energy = float_of_int(max(base.build_cost_energy, 1));
  let base_time = float_of_int(max(base.build_time, 1));
  let c_mass = float_of_int(max(compare_.UnitModel.build_cost_mass, 1));
  let c_energy = float_of_int(max(compare_.build_cost_energy, 1));
  let c_time = float_of_int(max(compare_.build_time, 1));

  {
    mass: Float.round(c_mass /. base_mass *. 100.0) /. 100.0,
    energy: Float.round(c_energy /. base_energy *. 100.0) /. 100.0,
    build_time: Float.round(c_time /. base_time *. 100.0) /. 100.0,
  };
};

let ratio_color = ratio =>
  if (ratio < 0.8) {
    "text-green-600 font-semibold";
  } else if (ratio > 5.0) {
    "text-red-600 font-semibold";
  } else if (ratio > 1.5) {
    "text-orange-500 font-semibold";
  } else {
    "text-yellow-600 font-medium";
  };

let ratio_badge_class = ratio =>
  if (ratio < 0.8) {
    "bg-green-100 text-green-800";
  } else if (ratio > 5.0) {
    "bg-red-100 text-red-800";
  } else if (ratio > 1.5) {
    "bg-orange-100 text-orange-800";
  } else {
    "bg-yellow-100 text-yellow-800";
  };

let mass_formatted = r => Printf.sprintf("%.2fx", r.mass);
let energy_formatted = r => Printf.sprintf("%.2fx", r.energy);
let build_time_formatted = r => Printf.sprintf("%.2fx", r.build_time);

type comparison = {
  unit: UnitModel.t,
  idx: int,
  ratio,
};

let generate_engineer_comparisons = (base_unit, selected_units) =>
  selected_units
  |> List.mapi((idx, unit) => {
       let ratio = calculate(base_unit, unit);
       {
         unit,
         idx,
         ratio,
       };
     });

type cross_comparison = {
  base_unit: UnitModel.t,
  comparisons: list((UnitModel.t, ratio)),
};

let generate_tiered_cross_comparisons = (base_unit, selected_units) => {
  let all_units = [base_unit, ...selected_units];
  let sorted =
    List.sort(
      (a, b) =>
        Int.compare(a.UnitModel.build_cost_mass, b.build_cost_mass),
      all_units,
    );

  let rec build_comparisons =
    fun
    | []
    | [_] => []
    | [base, ...rest] => {
        let comps =
          List.map(target => (target, calculate(base, target)), rest);
        [
          {
            base_unit: base,
            comparisons: comps,
          },
          ...build_comparisons(rest),
        ];
      };

  build_comparisons(sorted);
};

let total_mass_cost = units =>
  List.fold_left((acc, u) => acc + u.UnitModel.build_cost_mass, 0, units);

let total_energy_cost = units =>
  List.fold_left(
    (acc, u) => acc + u.UnitModel.build_cost_energy,
    0,
    units,
  );

let format_number = n =>
  if (n < 1000) {
    string_of_int(n);
  } else {
    let s = string_of_int(n);
    let chars = s |> String.to_seq |> List.of_seq |> List.rev;
    let rec insert_commas = (i, acc) =>
      fun
      | [] => acc
      | [c, ...rest] => {
          let acc = i > 0 && i mod 3 == 0 ? [',', ...acc] : acc;
          insert_commas(i + 1, [c, ...acc], rest);
        };
    let result = insert_commas(0, [], chars);
    result |> List.to_seq |> String.of_seq;
  };
