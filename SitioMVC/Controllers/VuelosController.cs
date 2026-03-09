using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

using Entidades_Compartidas;
using Logica;

namespace SitioMVC.Controllers
{
    public class VuelosController : Controller
    {        
        public ActionResult FormListarVuelos(string DatoFiltro)
        {
            try
            {
                // Compruebo Login
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    List<Vuelos> _listaVuelos = FabricaL.GetLogicaVuelo().Listar(empleadoLogueado);
                    if (_listaVuelos.Count > 0)
                    {
                        if (string.IsNullOrEmpty(DatoFiltro))
                            return View(_listaVuelos);
                        else
                        {
                            _listaVuelos = _listaVuelos.Where(V => V.Codigo.ToLower().StartsWith(DatoFiltro.ToLower())).ToList();
                            return View(_listaVuelos);
                        }
                    }
                    else
                        throw new Exception("No hay Vuelos para mostrar");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new List<Vuelos>());
            }
        }

        [HttpGet]
        public ActionResult FormAltaVuelo()
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");

                ViewBag.ListaEstadosPartida = CargoEstadosControl(empleadoLogueado);
                ViewBag.ListaEstadosArribo = CargoEstadosControl(empleadoLogueado);

                return View();
            }
            catch (Exception ex)
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                ViewBag.ListaEstadosPartida = CargoEstadosControl(empleadoLogueado);
                ViewBag.ListaEstadosArribo = CargoEstadosControl(empleadoLogueado);
                ViewBag.Mensaje = ex.Message;
                return View();
            }            
        }

        [HttpPost]
        public ActionResult FormAltaVuelo(Vuelos V, string CodigoPartida, string CodigoArribo)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    if (!string.IsNullOrEmpty(CodigoPartida))
                        V.EstadoPartida = FabricaL.GetLogicaEstado().Buscar(CodigoPartida, empleadoLogueado);
                    if (!string.IsNullOrEmpty(CodigoArribo))
                        V.EstadoArribo = FabricaL.GetLogicaEstado().Buscar(CodigoArribo, empleadoLogueado);
                            
                    V.Validar();

                    FabricaL.GetLogicaVuelo().Alta(V, empleadoLogueado);
                    
                    return RedirectToAction("FormListarVuelos", "Vuelos");
                }
            }
            catch (Exception ex)
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                ViewBag.ListaEstadosPartida = CargoEstadosControl(empleadoLogueado);
                ViewBag.ListaEstadosArribo = CargoEstadosControl(empleadoLogueado);
                ViewBag.Mensaje = ex.Message;
                return View(V);
            }
        }

        [HttpGet]
        public ActionResult FormModificarVuelo(string Codigo)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Vuelos unVuelo = FabricaL.GetLogicaVuelo().Buscar(Codigo, empleadoLogueado);

                    if (unVuelo == null)
                        throw new Exception("No se encontró el Vuelo");
                    else
                    {
                        ViewBag.ListaEstadosPartida = CargoEstadosConSeleccion(empleadoLogueado, unVuelo.EstadoPartida.Codigo);
                        ViewBag.ListaEstadosArribo = CargoEstadosConSeleccion(empleadoLogueado, unVuelo.EstadoArribo.Codigo);
                        
                        return View(unVuelo);
                    }                        
                }
            }
            catch (Exception ex)
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                ViewBag.ListaEstadosPartida = CargoEstadosControl(empleadoLogueado);
                ViewBag.ListaEstadosArribo = CargoEstadosControl(empleadoLogueado);
                ViewBag.Mensaje = ex.Message;
                return View(new Vuelos());
            }
        }

        [HttpPost]
        public ActionResult FormModificarVuelo(Vuelos V, string CodigoPartida, string CodigoArribo)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    if (!string.IsNullOrEmpty(CodigoPartida))
                        V.EstadoPartida = FabricaL.GetLogicaEstado().Buscar(CodigoPartida, empleadoLogueado);
                    if (!string.IsNullOrEmpty(CodigoArribo))
                        V.EstadoArribo = FabricaL.GetLogicaEstado().Buscar(CodigoArribo, empleadoLogueado);

                    V.Validar();

                    FabricaL.GetLogicaVuelo().Modificar(V, empleadoLogueado);

                    return RedirectToAction("FormListarVuelos", "Vuelos");
                }
            }
            catch (Exception ex)
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                ViewBag.ListaEstadosPartida = CargoEstadosConSeleccion(empleadoLogueado, V.EstadoPartida.Codigo);
                ViewBag.ListaEstadosArribo = CargoEstadosConSeleccion(empleadoLogueado, V.EstadoArribo.Codigo);
                ViewBag.Mensaje = ex.Message;
                return View(V);
            }
        }

        [HttpGet]
        public ActionResult FormBajaVuelo(string Codigo)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Vuelos unVuelo = FabricaL.GetLogicaVuelo().Buscar(Codigo, empleadoLogueado);

                    if (unVuelo == null)
                        throw new Exception("No se encontró el Vuelo");
                    else
                    {
                        ViewBag.ListaEstadosPartida = CargoEstadosConSeleccion(empleadoLogueado, unVuelo.EstadoPartida.Codigo);
                        ViewBag.ListaEstadosArribo = CargoEstadosConSeleccion(empleadoLogueado, unVuelo.EstadoArribo.Codigo);

                        return View(unVuelo);
                    }
                }
            }
            catch (Exception ex)
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                ViewBag.ListaEstadosPartida = CargoEstadosControl(empleadoLogueado);
                ViewBag.ListaEstadosArribo = CargoEstadosControl(empleadoLogueado);
                ViewBag.Mensaje = ex.Message;
                return View(new Vuelos());
            }
        }

        [HttpPost]
        public ActionResult FormBajaVuelo(Vuelos V)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {                                        
                    FabricaL.GetLogicaVuelo().Eliminar(V, empleadoLogueado);

                    return RedirectToAction("FormListarVuelos", "Vuelos");
                }
            }
            catch (Exception ex)
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                ViewBag.ListaEstadosPartida = CargoEstadosConSeleccion(empleadoLogueado);
                ViewBag.ListaEstadosArribo = CargoEstadosConSeleccion(empleadoLogueado, V.EstadoArribo.Codigo);
                ViewBag.Mensaje = ex.Message;
                return View(V);
            }
        }

        public ActionResult FormConsultarVuelo(string Codigo, string CodigoPartida, string CodigoArribo)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Vuelos unVuelo = FabricaL.GetLogicaVuelo().Buscar(Codigo, empleadoLogueado);
                    if (unVuelo != null)
                    {                        
                        if (!string.IsNullOrEmpty(CodigoPartida))
                            unVuelo.EstadoPartida = FabricaL.GetLogicaEstado().Buscar(CodigoPartida, empleadoLogueado);
                        if (!string.IsNullOrEmpty(CodigoArribo))
                            unVuelo.EstadoArribo = FabricaL.GetLogicaEstado().Buscar(CodigoArribo, empleadoLogueado);

                        return View(unVuelo);
                    }                    
                    else
                        throw new Exception("El Vuelo no existe - Pruebe nuevamente");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new Estados());
            }
        }

        internal SelectList CargoEstadosControl(Empleados empleadoLogueado)
        {            
            List<Estados> _listaEstados = FabricaL.GetLogicaEstado().Listar(empleadoLogueado);
            _listaEstados = _listaEstados.OrderBy(E => E.Nombre).ToList();
            return new SelectList(_listaEstados, "Codigo", "Nombre");
        }

        internal SelectList CargoEstadosConSeleccion(Empleados empleadoLogueado, string seleccionado = null)
        {
            List<Estados> _listaEstados = FabricaL.GetLogicaEstado().Listar(empleadoLogueado);
            _listaEstados = _listaEstados.OrderBy(E => E.Nombre).ToList();
            return new SelectList(_listaEstados, "Codigo", "Nombre", seleccionado);
        }
    }
}