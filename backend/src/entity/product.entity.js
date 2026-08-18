"use strict";
import { EntitySchema } from "typeorm";

const ProductSchema = new EntitySchema({
  name: "Product",
  tableName: "products",
  columns: {
    id: {
      type: "int",
      primary: true,
      generated: true,
    },
    nombre: {
      type: "varchar",
      length: 100,
      nullable: false,
    },
    precio: {
      type: "int",
      nullable: false,
    },
    stock: {
      type: "int",
      nullable: false,
      default: 0,
    },
  },
});

export default ProductSchema;
