using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

using Entidades_Compartidas;
using Logica;

namespace SitioMVC.Controllers
{
    public class HospedajesController : Controller
    {        
        public ActionResult FormListarHospedajes(string DatoFiltro)
        {
            try
            {
                // Compruebo Login
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    List<Hospedajes> _listaHospedajes = FabricaL.GetLogicaHospedaje().Listar(empleadoLogueado);
                    if (_listaHospedajes.Count > 0)
                    {
                        if (string.IsNullOrEmpty(DatoFiltro))
                            return View(_listaHospedajes);
                        else
                        {
                            _listaHospedajes = _listaHospedajes.Where(H => H.Nombre.ToLower().Contains(DatoFiltro.ToLower())).ToList();
                            return View(_listaHospedajes);
                        }
                    }
                    else
                        throw new Exception("No hay Hospedajes para mostrar");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new List<Hospedajes>());
            }
        }

        public ActionResult FormListarCRUDHospedajes()
        {
            try
            {
                // Compruebo Login
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    List<Hospedajes> _listaHospedajes = FabricaL.GetLogicaHospedaje().Listar(empleadoLogueado);
                    if (_listaHospedajes.Count > 0)                    
                        return View(_listaHospedajes);
                    
                    else
                        throw new Exception("No hay Hospedajes para mostrar");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new List<Hospedajes>());
            }
        }

        [HttpGet]
        public ActionResult FormAltaHospedaje()
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");

                ViewBag.ListaTipos = CargoTipos();

                ViewBag.ListaEstados = CargoEstadosControl(empleadoLogueado);            

                return View();
            }
            catch (Exception ex)
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                ViewBag.ListaTipos = CargoTipos();
                ViewBag.ListaEstados = CargoEstadosControl(empleadoLogueado);                
                ViewBag.Mensaje = ex.Message;
                return View();
            }
        }

        [HttpPost]
        public ActionResult FormAltaHospedaje(Hospedajes H, string CodigoEstado)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    if (!string.IsNullOrEmpty(CodigoEstado))
                        H.Estado = FabricaL.GetLogicaEstado().Buscar(CodigoEstado, empleadoLogueado);                    
                    
                    H.Validar();

                    FabricaL.GetLogicaHospedaje().Alta(H, empleadoLogueado);

                    return RedirectToAction("FormListarCRUDHospedajes", "Hospedajes");
                }
            }
            catch (Exception ex)
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                ViewBag.ListaTipos = CargoTipos();
                ViewBag.ListaEstados = CargoEstadosControl(empleadoLogueado);                
                ViewBag.Mensaje = ex.Message;
                return View(H);
            }
        }

        [HttpGet]
        public ActionResult FormModificarHospedaje(string CodigoInterno)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Hospedajes unHospedaje = FabricaL.GetLogicaHospedaje().Buscar(CodigoInterno, empleadoLogueado);

                    if (unHospedaje == null)
                        throw new Exception("No se encontró el Hospedaje");
                    else
                    {
                        ViewBag.ListaTipos = CargoTipos(unHospedaje.TipoH);
                        ViewBag.ListaEstados = CargoEstadosControl(empleadoLogueado, unHospedaje.Estado.Codigo);

                        return View(unHospedaje);
                    }
                }
            }
            catch (Exception ex)
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                ViewBag.ListaTipos = CargoTipos();
                ViewBag.ListaEstados = CargoEstadosControl(empleadoLogueado);
                ViewBag.Mensaje = ex.Message;
                return View(new Hospedajes());
            }
        }

        [HttpPost]
        public ActionResult FormModificarHospedaje(Hospedajes H, string Tipo, string CodigoEstado)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    if (!string.IsNullOrEmpty(CodigoEstado))
                        H.Estado = FabricaL.GetLogicaEstado().Buscar(CodigoEstado, empleadoLogueado);                    

                    H.Validar();

                    FabricaL.GetLogicaHospedaje().Modificar(H, empleadoLogueado);

                    return RedirectToAction("FormListarCRUDHospedajes", "Hospedajes");
                }
            }
            catch (Exception ex)
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                ViewBag.ListaTipos = CargoTipos(Tipo);
                ViewBag.ListaEstados = CargoEstadosControl(empleadoLogueado, CodigoEstado);
                ViewBag.Mensaje = ex.Message;
                return View(H);
            }
        }

        [HttpGet]
        public ActionResult FormBajaHospedaje(string CodigoInterno)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Hospedajes unHospedaje = FabricaL.GetLogicaHospedaje().Buscar(CodigoInterno, empleadoLogueado);

                    if (unHospedaje == null)
                        throw new Exception("No se encontró el Hospedaje");
                    else
                    {
                        return View(unHospedaje);
                    }
                }
            }
            catch (Exception ex)
            {   
                ViewBag.Mensaje = ex.Message;
                return View(new Hospedajes());
            }
        }

        [HttpPost]
        public ActionResult FormBajaHospedaje(Hospedajes H)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {   
                    FabricaL.GetLogicaHospedaje().Eliminar(H, empleadoLogueado);

                    return RedirectToAction("FormListarCRUDHospedajes", "Hospedajes");
                }
            }
            catch (Exception ex)
            {                
                ViewBag.Mensaje = ex.Message;
                return View(H);
            }
        }

        public ActionResult FormConsultarHospedaje(string CodigoInterno)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Hospedajes unHospedaje = FabricaL.GetLogicaHospedaje().Buscar(CodigoInterno, empleadoLogueado);
                    if (unHospedaje != null)
                    {                                              
                        return View(unHospedaje);
                    }
                    else
                        throw new Exception("El Hospedaje no existe - Pruebe nuevamente");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new Hospedajes());
            }        
        }

        public ActionResult FormListarPVPorHospedaje(string CodigoInterno)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Hospedajes unHospedaje = FabricaL.GetLogicaHospedaje().Buscar(CodigoInterno, empleadoLogueado);
                    List <PaquetesViajes> _listaPV = FabricaL.GetLogicaPaqueteViaje().ListarPaquetesViajesPorHospedaje(unHospedaje, empleadoLogueado);
                    if (_listaPV.Count > 0)
                    {                       
                        return View(_listaPV);
                    }
                    else
                        throw new Exception("No existen Paquetes Viajes asociados al Hospedaje");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new PaquetesViajes());
            }
        }

        internal SelectList CargoEstadosControl(Empleados empleadoLogueado, string seleccionado = null)
        {
            List<Estados> _listaEstados = FabricaL.GetLogicaEstado().Listar(empleadoLogueado);
            _listaEstados = _listaEstados.OrderBy(E => E.Nombre).ToList();
            return new SelectList(_listaEstados, "Codigo", "Nombre", seleccionado);
        }       

        internal SelectList CargoTipos(string seleccionado = null)
        {
            return new SelectList(Hospedajes.TiposValidos(), seleccionado);
        }
    }
}