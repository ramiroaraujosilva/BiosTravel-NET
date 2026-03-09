using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

using Entidades_Compartidas;
using Logica;

namespace SitioMVC.Controllers
{
    public class EstadosController : Controller
    {        
        public ActionResult FormListarEstados(string DatoFiltro)
        {
            try
            {
                // Compruebo Login
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    List<Estados> _listaEstados = FabricaL.GetLogicaEstado().Listar(empleadoLogueado);
                    if (_listaEstados.Count > 0)
                    {
                        if (string.IsNullOrEmpty(DatoFiltro))
                            return View(_listaEstados);
                        else
                        {
                            _listaEstados = _listaEstados.Where(E => E.Pais.ToLower().StartsWith(DatoFiltro.ToLower())).ToList();
                            return View(_listaEstados);
                        }
                    }
                    else
                        throw new Exception("No hay Estados para mostrar");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new List<Estados>());
            }
        }

        [HttpGet]
        public ActionResult FormAltaEstado()
        {
            return View();
        }

        [HttpPost]
        public ActionResult FormAltaEstado(Estados E)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    E.Validar();

                    FabricaL.GetLogicaEstado().Alta(E, empleadoLogueado);

                    return RedirectToAction("FormListarEstados", "Estados");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(E);
            }
        }

        [HttpGet]
        public ActionResult FormModificarEstado(string Codigo)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Estados unEstado = FabricaL.GetLogicaEstado().Buscar(Codigo, empleadoLogueado);

                    if (unEstado == null)
                        throw new Exception("No se encontró el Estado");
                    else
                        return View(unEstado);
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new Estados());
            }
        }

        [HttpPost]
        public ActionResult FormModificarEstado(Estados E)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    E.Validar();

                    FabricaL.GetLogicaEstado().Modificar(E, empleadoLogueado);

                    return RedirectToAction("FormListarEstados", "Estados");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(E);
            }
        }

        public ActionResult FormConsultarEstado(string Codigo)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Estados unEstado = FabricaL.GetLogicaEstado().Buscar(Codigo, empleadoLogueado);

                    if (unEstado != null)
                        return View(unEstado);
                    else
                        throw new Exception("El Estado no existe - Pruebe nuevamente");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new Estados());
            }
        }

        [HttpGet]
        public ActionResult FormBajaEstado(string Codigo)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Estados unEstado = FabricaL.GetLogicaEstado().Buscar(Codigo, empleadoLogueado);

                    if (unEstado == null)
                        throw new Exception("No se encontró el Estado");
                    else
                        return View(unEstado);
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new Estados());
            }
        }

        [HttpPost]
        public ActionResult FormBajaEstado(Estados E)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {                    
                    FabricaL.GetLogicaEstado().Eliminar(E, empleadoLogueado);

                    return RedirectToAction("FormListarEstados", "Estados");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(E);
            }
        }
    }
}