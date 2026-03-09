using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Entidades_Compartidas;
using Persistencia;

namespace Logica
{
    internal class LPaqueteViaje : Interfaces.ILPaqueteViaje
    {
        #region Singleton

        // Singleton
        private static LPaqueteViaje _Instancia = null;

        // Constructor por defecto
        private LPaqueteViaje() { }

        // GetInstancia
        public static LPaqueteViaje GetInstancia()
        {
            if (_Instancia == null)
                _Instancia = new LPaqueteViaje();

            return _Instancia;
        }

        #endregion

        #region Operaciones

        public void Alta(PaquetesViajes unPaqueteViaje, Empleados pLogueo)
        {
            try
            {
                //Precios
                double totalCostoHospedajes = 0;
                foreach (Incluyen unH in unPaqueteViaje.IncluyenHospedajes)
                {
                    double precioHospedaje = unH.Hospedaje.PrecioH * unH.CantNoches;
                    totalCostoHospedajes += precioHospedaje;
                }

                double precioBase = totalCostoHospedajes + unPaqueteViaje.VueloIda.PrecioV + unPaqueteViaje.VueloVuelta.PrecioV;
                unPaqueteViaje.PrecioIndividual = precioBase * 1.35;
                unPaqueteViaje.PrecioDosP = (precioBase * 2) * 1.10;
                unPaqueteViaje.PrecioTresP = (precioBase * 3) * 1.10;

                // cantidad dias
                unPaqueteViaje.CantidadDiasP = (unPaqueteViaje.VueloVuelta.FechaHoraP.Date - unPaqueteViaje.VueloIda.FechaHoraP.Date).Days;

                // validar datos ingresados
                unPaqueteViaje.Validar();

                // verificar vuelos con estados
                if (unPaqueteViaje.VueloIda.EstadoArribo.Codigo == unPaqueteViaje.Estado.Codigo && unPaqueteViaje.VueloVuelta.EstadoPartida.Codigo == unPaqueteViaje.Estado.Codigo)
                {                    
                    FabricaP.GetPersistenciaPaqueteViaje().Alta(unPaqueteViaje, pLogueo);
                }
                else
                    throw new Exception("El vuelo de partida debe ser posterior a la hora actual, y el vuelo de arribo posterior al de partida");
                    
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }        
        }

        public PaquetesViajes Buscar(string pCodigo, Empleados pLogueo)
        {
            return (FabricaP.GetPersistenciaPaqueteViaje().Buscar(pCodigo, pLogueo));
        }
        public List<PaquetesViajes> Listar(Empleados pLogueo)
        {
            return (FabricaP.GetPersistenciaPaqueteViaje().Listar(pLogueo));
        }
        public List<PaquetesViajes> ListarPaquetesViajesPorHospedaje(Hospedajes pHospedajes, Empleados pLogueo)
        {
            return (FabricaP.GetPersistenciaPaqueteViaje().ListarPaquetesViajesPorHospedaje(pHospedajes ,pLogueo));
        }

        #endregion
    }


}
