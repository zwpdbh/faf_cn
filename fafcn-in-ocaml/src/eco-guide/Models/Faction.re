type t =
  | Uef
  | Cybran
  | Aeon
  | Seraphim;

let to_string =
  fun
  | Uef => "UEF"
  | Cybran => "CYBRAN"
  | Aeon => "AEON"
  | Seraphim => "SERAPHIM";

let all = [Uef, Cybran, Aeon, Seraphim];

let engineer_id =
  fun
  | Uef => "UEL0105"
  | Cybran => "URL0105"
  | Aeon => "UAL0105"
  | Seraphim => "XSL0105";

let badge_class =
  fun
  | Uef => "bg-blue-100 text-blue-800"
  | Cybran => "bg-red-100 text-red-800"
  | Aeon => "bg-emerald-100 text-emerald-800"
  | Seraphim => "bg-violet-100 text-violet-800";

let bg_class =
  fun
  | Uef => "unit-bg-uef"
  | Cybran => "unit-bg-cybran"
  | Aeon => "unit-bg-aeon"
  | Seraphim => "unit-bg-seraphim";

let tab_active_class =
  fun
  | Uef => "border-blue-500 text-blue-600"
  | Cybran => "border-red-500 text-red-600"
  | Aeon => "border-emerald-500 text-emerald-600"
  | Seraphim => "border-violet-500 text-violet-600";
