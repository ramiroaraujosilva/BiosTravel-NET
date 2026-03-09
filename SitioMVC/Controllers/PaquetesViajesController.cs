using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

using Entidades_Compartidas;
using Logica;

namespace SitioMVC.Controllers
{
    public class PaquetesViajesController : Controller
    {        
        public ActionResult FormListarPaquetesViajes(string DatoFiltro)
        {
            try
            {
                // Compruebo Login
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    List<PaquetesViajes> _listaPaquetesViajes = FabricaL.GetLogicaPaqueteViaje().Listar(empleadoLogueado);
                    if (_listaPaquetesViajes.Count > 0)
                    {
                        if (string.IsNullOrEmpty(DatoFiltro))
                            return View(_listaPaquetesViajes);
                        else
                        {
                            _listaPaquetesViajes = _listaPaquetesViajes.Where(P => P.Estado.Nombre.ToLower().StartsWith(DatoFiltro.ToLower())).ToList();
                            return View(_listaPaquetesViajes);
                        }
                    }
                    else
                        throw new Exception("No hay Paquetes para mostrar");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new List<PaquetesViajes>());
            }
        }

        [HttpGet]
        public ActionResult FormAltaPaqueteViaje()
        {
            try
            {
                // Compruebo Login
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    ViewBag.ListaEstados = CargoEstadosControl(empleadoLogueado);
                    return View();
                }
            }
            catch (Exception ex)
            {
                ViewBag.ListaEstados = new SelectList(null);
                ViewBag.Mensaje = ex.Message;
                return View();
            }          
        }

        [HttpPost]
        public ActionResult FormAltaPaqueteViaje(PaquetesViajes PV, string CodigoEstado)
        {
            try
            {
                // Compruebo Login
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    if (!string.IsNullOrEmpty(CodigoEstado))                                           
                        PV.Estado = FabricaL.GetLogicaEstado().Buscar(CodigoEstado, empleadoLogueado);                        
                    
                    PV.Empleado = empleadoLogueado;

                    PV.IncluyenHospedajes = new List<Incluyen>();

                    Session["Paquete"] = PV;

                    return RedirectToAction("FormAltaPaqueteViaje2", "PaquetesViajes");
                }
            }
            catch (Exception ex)
            {
                ViewBag.ListaEstados = new SelectList(null);
                ViewBag.Mensaje = ex.Message;
                return View();
            }
        }

        [HttpGet]
        public ActionResult FormAltaPaqueteViaje2()
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    PaquetesViajes PV = Session["Paquete"] as PaquetesViajes;
                    if (PV == null)
                        return RedirectToAction("FormAltaPaqueteViaje", "PaquetesViajes");

                    ViewBag.ListaVuelosIda = CargoVuelosIdaControl(empleadoLogueado, PV.Estado);
                    ViewBag.ListaVuelosVuelta = CargoVuelosVueltaControl(empleadoLogueado, PV.Estado);

                    

                    return View();
                }
            }
            catch (Exception ex)
            {
                ViewBag.ListaVuelosIda = new SelectList(null);
                ViewBag.ListaVuelosVuelta = new SelectList(null);                
                ViewBag.Mensaje = ex.Message;
                return View();
            }
        }

        [HttpPost]
        public ActionResult FormAltaPaqueteViaje2(string vueloIda, string vueloVuelta)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    PaquetesViajes PV = Session["Paquete"] as PaquetesViajes;

                    PV.VueloIda = FabricaL.GetLogicaVuelo().Buscar(vueloIda, empleadoLogueado);
                    PV.VueloVuelta = FabricaL.GetLogicaVuelo().Buscar(vueloVuelta, empleadoLogueado);
                    

                    return RedirectToAction("FormAltaPaqueteViaje3", "PaquetesViajes");
                }                
            }
            catch (Exception ex)
            {
                ViewBag.ListaVuelosIda = new SelectList(null);
                ViewBag.ListaVuelosVuelta = new SelectList(null);                
                ViewBag.Mensaje = ex.Message;
                return View();
            }            
        }

        [HttpGet]
        public ActionResult FormAltaPaqueteViaje3()
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    PaquetesViajes PV = Session["Paquete"] as PaquetesViajes;
                    if (PV == null)
                        return RedirectToAction("FormAltaPaqueteViaje", "PaquetesViajes");

                    ViewBag.ListaHospedajes = CargoHospedajesControl(empleadoLogueado, PV.Estado);                     

                    return View();
                }
            }
            catch (Exception ex)
            {                
                ViewBag.ListaHospedajes = new SelectList(null);
                ViewBag.Mensaje = ex.Message;
                return View();
            }
        }

        [HttpPost]
        public ActionResult FormAltaPaqueteViaje3(string CodigoInterno, int CantNoches)
        {
            PaquetesViajes PV = null;
            Empleados empleadoLogueado = null;
            try
            {
                empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    PV = Session["Paquete"] as PaquetesViajes;                    

                    Hospedajes H = FabricaL.GetLogicaHospedaje().Buscar(CodigoInterno, empleadoLogueado);

                    Incluyen inc = new Incluyen(CantNoches, H);

                    inc.Validar();                    

                    if (PV.IncluyenHospedajes.Exists(i => i.Hospedaje.CodigoInterno == H.CodigoInterno))
                        throw new Exception("Ese hospedaje ya fue agregado al paquete");

                    PV.IncluyenHospedajes.Add(inc);                                                                                           

                    return RedirectToAction("FormAltaPaqueteViaje3", "PaquetesViajes");
                }                
            }
            catch (Exception ex)
            {
                ViewBag.ListaHospedajes = CargoHospedajesControl(empleadoLogueado, PV.Estado);
                ViewBag.Mensaje = ex.Message;
                return View();
            }            
        }

        [HttpGet]
        public ActionResult GuardarPaquete()
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    PaquetesViajes PV = Session["Paquete"] as PaquetesViajes;

                    FabricaL.GetLogicaPaqueteViaje().Alta(PV, empleadoLogueado);

                    return RedirectToAction("AltaExitosa", "PaquetesViajes");
                }                    
            }
            catch (Exception ex)
            {
                Session["ErrorHospedaje"] = ex.Message;
                return RedirectToAction("AltaError", "PaquetesViajes");
            }
        }
        public ActionResult AltaExitosa()
        {
            return View();
        }

        public ActionResult AltaError()
        {
            ViewBag.Mensaje = Session["ErrorHospedaje"] as string;
            return View();
        }

        public ActionResult FormConsultarPaqueteViaje(string Codigo)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    PaquetesViajes PV = FabricaL.GetLogicaPaqueteViaje().Buscar(Codigo, empleadoLogueado);
                    if (PV != null)
                    {
                        return View(PV);
                    }
                    else
                        throw new Exception("El Paquete Viaje no existe - Pruebe nuevamente");
                }
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new PaquetesViajes());
            }
        }

        internal SelectList CargoEstadosControl(Empleados empleadoLogueado)
        {
            List<Estados> _listaEstados = FabricaL.GetLogicaEstado().Listar(empleadoLogueado);
            _listaEstados = _listaEstados.OrderBy(E => E.Nombre).ToList();
            return new SelectList(_listaEstados, "Codigo", "Nombre");
        }
        internal SelectList CargoVuelosIdaControl(Empleados empleadoLogueado, Estados elEstado)
        {
            List<Vuelos> _listaVuelos = FabricaL.GetLogicaVuelo().Listar(empleadoLogueado);
            _listaVuelos = _listaVuelos.Where(V => V.EstadoArribo.Codigo == elEstado.Codigo).ToList();            
            return new SelectList(_listaVuelos, "Codigo", "VueloInfo");
        }
        internal SelectList CargoVuelosVueltaControl(Empleados empleadoLogueado, Estados elEstado)
        {
            List<Vuelos> _listaVuelos = FabricaL.GetLogicaVuelo().Listar(empleadoLogueado);
            _listaVuelos = _listaVuelos.Where(V => V.EstadoPartida.Codigo == elEstado.Codigo).ToList();
            return new SelectList(_listaVuelos, "Codigo", "VueloInfo");
        }
        internal SelectList CargoHospedajesControl(Empleados empleadoLogueado, Estados elEstado)
        {
            List<Hospedajes> _listaHospedajes = FabricaL.GetLogicaHospedaje().Listar(empleadoLogueado);
            _listaHospedajes = _listaHospedajes.Where(H => H.Estado.Codigo == elEstado.Codigo).ToList();
            return new SelectList(_listaHospedajes, "CodigoInterno", "Nombre");
        }
    }
}