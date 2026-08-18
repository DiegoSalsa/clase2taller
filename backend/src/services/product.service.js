"use strict";
import Product from "../entity/product.entity.js";
import { AppDataSource } from "../config/configDb.js";

export async function createProductService(body) {
  try {
    const repository = AppDataSource.getRepository(Product);
    const product = repository.create(body);
    const productSaved = await repository.save(product);

    return [productSaved, null];
  } catch (error) {
    console.error("Error al crear producto:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getProductsService() {
  try {
    const repository = AppDataSource.getRepository(Product);
    const products = await repository.find();

    return [products, null];
  } catch (error) {
    console.error("Error al obtener productos:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function getProductService(id) {
  try {
    const repository = AppDataSource.getRepository(Product);
    const product = await repository.findOne({ where: { id } });

    if (!product) return [null, "Producto no encontrado"];

    return [product, null];
  } catch (error) {
    console.error("Error al obtener producto:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function updateProductService(id, body) {
  try {
    const repository = AppDataSource.getRepository(Product);
    const product = await repository.findOne({ where: { id } });

    if (!product) return [null, "Producto no encontrado"];

    repository.merge(product, body);
    const productUpdated = await repository.save(product);

    return [productUpdated, null];
  } catch (error) {
    console.error("Error al modificar producto:", error);
    return [null, "Error interno del servidor"];
  }
}

export async function deleteProductService(id) {
  try {
    const repository = AppDataSource.getRepository(Product);
    const product = await repository.findOne({ where: { id } });

    if (!product) return [null, "Producto no encontrado"];

    const productDeleted = await repository.remove(product);

    return [productDeleted, null];
  } catch (error) {
    console.error("Error al eliminar producto:", error);
    return [null, "Error interno del servidor"];
  }
}
