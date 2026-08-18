"use strict";
import {
  createProductService,
  deleteProductService,
  getProductService,
  getProductsService,
  updateProductService,
} from "../services/product.service.js";
import {
  productCreateValidation,
  productQueryValidation,
  productUpdateValidation,
} from "../validations/product.validation.js";
import {
  handleErrorClient,
  handleErrorServer,
  handleSuccess,
} from "../handlers/responseHandlers.js";

export async function createProduct(req, res) {
  try {
    const { error } = productCreateValidation.validate(req.body);

    if (error) {
      return handleErrorClient(res, 400, "Error de validación", error.message);
    }

    const [product, errorProduct] = await createProductService(req.body);

    if (errorProduct) return handleErrorClient(res, 400, errorProduct);

    handleSuccess(res, 201, "Producto creado correctamente", product);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getProducts(req, res) {
  try {
    const [products, errorProducts] = await getProductsService();

    if (errorProducts) return handleErrorClient(res, 500, errorProducts);

    handleSuccess(res, 200, "Productos encontrados", products);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getProduct(req, res) {
  try {
    const { error } = productQueryValidation.validate(req.query);

    if (error) {
      return handleErrorClient(res, 400, "Error de validación", error.message);
    }

    const [product, errorProduct] = await getProductService(Number(req.query.id));

    if (errorProduct) return handleErrorClient(res, 404, errorProduct);

    handleSuccess(res, 200, "Producto encontrado", product);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function updateProduct(req, res) {
  try {
    const queryValidation = productQueryValidation.validate(req.query);
    const bodyValidation = productUpdateValidation.validate(req.body);

    if (queryValidation.error) {
      return handleErrorClient(
        res,
        400,
        "Error de validación",
        queryValidation.error.message,
      );
    }

    if (bodyValidation.error) {
      return handleErrorClient(
        res,
        400,
        "Error de validación",
        bodyValidation.error.message,
      );
    }

    const [product, errorProduct] = await updateProductService(
      Number(req.query.id),
      req.body,
    );

    if (errorProduct) return handleErrorClient(res, 404, errorProduct);

    handleSuccess(res, 200, "Producto modificado correctamente", product);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function deleteProduct(req, res) {
  try {
    const { error } = productQueryValidation.validate(req.query);

    if (error) {
      return handleErrorClient(res, 400, "Error de validación", error.message);
    }

    const [product, errorProduct] = await deleteProductService(Number(req.query.id));

    if (errorProduct) return handleErrorClient(res, 404, errorProduct);

    handleSuccess(res, 200, "Producto eliminado correctamente", product);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}
