"use strict";
import Joi from "joi";

export const productQueryValidation = Joi.objetc({
    id: Joi.number().integer().positive().required(),
}).unknown(false);

export const productCreateValidation = Joi.objetc({
    nombre: Joi.string().min(2).max(100).required(),
    precio: Joi.number().integer().min(0).required(),
    stock: Joi.number().integer().min(0).required(),
}).unknown(false);

export const productUpdateValidation = Joi.objetc({
    nombre: Joi.string().min(2).max(100),
    precio: Joi.number().integer().min(0),
    stock: Joi.number().integer().min(0),
})
.or ("nombre", "precio", "stock")
.unknown(false);
