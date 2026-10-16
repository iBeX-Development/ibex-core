import {Option} from "~/interfaces/option";

export interface Templateheader {
  id:          number;
  status:      string;
  code:        number;
  name:        string;
  help:        string;
  validation:  string;
  outer_class: string;
  label_class: string;
  inner_class: string;
  input_class: string;
  help_class:  string;
  label:       string;
  options:     Option[];
}
