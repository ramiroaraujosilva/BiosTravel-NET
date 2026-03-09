using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.ComponentModel;
using System.ComponentModel.DataAnnotations;

namespace Entidades_Compartidas
{
    public class Vuelos
    {
        // atributos
        private string codigo;
        private DateTime fechaHoraP;
        private DateTime fechaHoraL;
        private double precioV;
        private Estados estadoPartida;
        private Estados estadoArribo;

        // propiedades
        public string Codigo
        {
            get { return codigo; }
            set { codigo = value; }
        }
        [DisplayName("Fecha y hora de partida")]
        [DataType(DataType.DateTime)]
        public DateTime FechaHoraP
        {
            get { return fechaHoraP; }
            set { fechaHoraP = value; }
        }

        [DisplayName("Fecha y hora de llegada")]
        [DataType(DataType.DateTime)]
        public DateTime FechaHoraL
        {
            get { return fechaHoraL; }
            set { fechaHoraL = value; }
        }

        [DisplayName("Precio")]
        public double PrecioV
        {
            get { return precioV; }
            set { precioV = value; }
        }

        [DisplayName("Estado de partida")]
        public Estados EstadoPartida
        {
            get { return estadoPartida; }
            set { estadoPartida = value; }
        }

        [DisplayName("Estado de arribo")]
        public Estados EstadoArribo
        {
            get { return estadoArribo; }
            set { estadoArribo = value; }
        }

        // propiedad para utilizar en los SelectList
        public string VueloInfo
        {
            get { return "Parte de " + EstadoPartida.Nombre + " hacia a " + EstadoArribo.Nombre + " - " + FechaHoraP.ToString("dd/MM/yyyy HH:mm"); }
        }

        // constructor completo
        public Vuelos(string pCodigo, DateTime pFechaHoraP, DateTime pFechaHoraL, double pPrecioV, Estados pEstadoPartida, Estados pEstadoArribo) 
        {
            Codigo = pCodigo;
            FechaHoraP = pFechaHoraP;
            FechaHoraL = pFechaHoraL;
            PrecioV = pPrecioV;
            EstadoPartida = pEstadoPartida;
            EstadoArribo = pEstadoArribo;
        }

        // constructor por defecto
        public Vuelos() { }

        // operación validar --> código defensivo
        public void Validar()
        {
            if (this.Codigo.Trim().Length != 10)
                throw new Exception("El código del Vuelo debe de ser de 10 caracteres de largo exactamente");            
            if (this.FechaHoraL <= this.FechaHoraP)
                throw new Exception("La fecha de llegada del Vuelo debe ser a posterior a la de Partida");
            if (this.PrecioV <= 0)
                throw new Exception("El precio del Vuelo debe ser mayor a 0");
            if (this.EstadoPartida == null)
                throw new Exception("Debe seleccionar el Estado de partida");
            if (this.EstadoArribo == null)
                throw new Exception("Debe seleccionar el Estado de arribo");
        }
    }
}
