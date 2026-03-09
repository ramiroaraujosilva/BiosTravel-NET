using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

using Entidades_Compartidas;
using Logica;

namespace SitioMVC.Controllers
{
    public class EmpleadosController : Controller
    {        
        [HttpGet]
        public ActionResult Logueo()
        {
            return View();
        }

        [HttpPost]
        public ActionResult Logueo(string Usuario, string PassUsu)
        {
            try
            {
                Empleados empleadoLogueado = FabricaL.GetLogicaEmpleado().Logueo(Usuario, PassUsu);

                if (empleadoLogueado != null)
                {
                    Session["Logueo"] = empleadoLogueado;

                    return RedirectToAction("MantenimientoEmpleados", "Empleados");
                }
                else
                    throw new Exception("Ha ocurrido un error, intente loguearse nuevamente");                
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View();
            }
        }

        public ActionResult MantenimientoEmpleados(string DatoFiltro)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    List<Empleados> _listaEmpleados = FabricaL.GetLogicaEmpleado().Listar(empleadoLogueado);

                    if (_listaEmpleados.Count > 0)
                    {
                        if (string.IsNullOrEmpty(DatoFiltro))
                            return View(_listaEmpleados);
                        else
                        {
                            _listaEmpleados = _listaEmpleados.Where(E => E.NombreCompleto.ToLower().StartsWith(DatoFiltro.ToLower())).ToList();
                            return View(_listaEmpleados);
                        }
                    }
                    else
                        throw new Exception("No hay empleados para mostrar");
                }                
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new List<Empleados>());
            }
        }

        public ActionResult Deslogueo()
        {
            Session["Logueo"] = null;
            return RedirectToAction("Logueo", "Empleados");
        }

        [HttpGet]
        public ActionResult FormAltaEmpleado()
        {
            return View();
        }

        [HttpPost]
        public ActionResult FormAltaEmpleado(Empleados E)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    E.Validar();

                    FabricaL.GetLogicaEmpleado().NuevoUsuario(E, empleadoLogueado);
                    
                    return RedirectToAction("MantenimientoEmpleados", "Empleados");
                }                    
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(E);
            }
        }

        [HttpGet]
        public ActionResult FormModificarEmpleado(string Usuario)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Empleados unEmpleado = FabricaL.GetLogicaEmpleado().Buscar(Usuario, empleadoLogueado);

                    if (unEmpleado == null)
                        throw new Exception("No se encontró el Empleado");
                    else
                        return View(unEmpleado);
                }                    
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new Empleados());
            }
        }

        [HttpPost]
        public ActionResult FormModificarEmpleado(Empleados E, string passActual, string nuevaPass, string confirmarPass)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    // verifico las contraseña ingresada para validar la modificación
                    if (passActual.Trim() != E.PassUsu.Trim())
                        throw new Exception("La contraseña actual ingresada no es la correcta");

                    // si no se ingresa nueva contraseña es porque no se la quiere cambiar
                    if (nuevaPass.Trim().Length == 0)
                    {
                        E.Validar();

                        FabricaL.GetLogicaEmpleado().Modificar(E, empleadoLogueado);

                        return RedirectToAction("MantenimientoEmpleados", "Empleados");
                    }
                    
                    if (nuevaPass.Trim() != confirmarPass.Trim())
                        throw new Exception("La confirmación de la contraseña no es correcta");

                    E.PassUsu = nuevaPass.Trim();

                    E.Validar();

                    FabricaL.GetLogicaEmpleado().Modificar(E, empleadoLogueado);

                    ViewBag.Mensaje = "Modificado correctamente";
                    return View();
                }                    
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(E);
            }
        }
        
        public ActionResult FormConsultarEmpleado(string Usuario)
        {
            try
            {
                Empleados empleadoLogueado = Session["Logueo"] as Empleados;
                if (empleadoLogueado == null)
                    return RedirectToAction("Logueo", "Empleados");
                else
                {
                    Empleados unEmpleado = FabricaL.GetLogicaEmpleado().Buscar(Usuario, empleadoLogueado);

                    if (unEmpleado != null)                                           
                        return View(unEmpleado);                    
                    else
                        throw new Exception("El Empleado no existe - Pruebe nuevamente");
                }                    
            }
            catch (Exception ex)
            {
                ViewBag.Mensaje = ex.Message;
                return View(new Empleados());
            }
        }
    }
}