locals {
  all_of_conditions = [
    for condition in var.condition.all_of : length(condition.any_of) > 0 ? {
      anyOf = [
        for any_of_condition in condition.any_of : merge(
          {
            field = any_of_condition.field
          },
          any_of_condition.equals == null ? {} : { equals = any_of_condition.equals },
          length(any_of_condition.contains_any) == 0 ? {} : { containsAny = any_of_condition.contains_any }
        )
      ]
      } : merge(
      {
        field = condition.field
      },
      condition.equals == null ? {} : { equals = condition.equals },
      length(condition.contains_any) == 0 ? {} : { containsAny = condition.contains_any }
    )
  ]
}
