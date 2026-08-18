"use strict";

export async function getempresaA(req, res) {
  try {
    const { } = req.query;

    const { error } = empresaQueryValidation.validate({ });

    if (error) return handleErrorClient(res, 400, error.message);

    const [empresa, errorEmpresa] = await getEmpresaService({ });

    if (errorEmpresa) return handleErrorClient(res, 404, errorEmpresa);

    handleSuccess(res, 200, "Empresa encontrada", empresa);
  } catch (error) {
    handleErrorServer(res, 500, error.message);
  }
}

export async function getEmpresa(req, res) {
  try {
    const [empresas, errorEmpresas] = await getEmpresasService();

    if (errorEmpresas) return handleErrorClient(res, 404, errorUsers);

    empresas.length === 0
      ? handleSuccess(res, 204)
      : handleSuccess(res, 200, "Empresas encontradas", empresas);
  } catch (error) {
    handleErrorServer(
      res,
      500,
      error.message,
    );
  }
