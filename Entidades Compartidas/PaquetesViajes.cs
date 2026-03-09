using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.ComponentModel;

namespace Entidades_Compartidas
{
    public class PaquetesViajes
    {
        private int codigo;
        private string titulo;
        private string descripcion;
        private int cantidadDiasP;
        private double precioIndividual;
        private double precioDosP;
        private double precioTresP;
        private Empleados empleado;
        private Vuelos vueloIda;
        private Vuelos vueloVuelta;
        private Estados estado;
        private List<Incluyen> incluyenHospedajes;

        // propiedades
        [DisplayName("Código")]
        public int Codigo
        {
            get { return codigo; }
            set { codigo = value; }
        }

        [DisplayName("Título")]
        public string Titulo
        {
            get { return titulo; }
            set { titulo = value; }
        }

        [DisplayName("Descripción")]
        public string Descripcion
        {
            get { return descripcion; }
            set { descripcion = value; }
        }

        [DisplayName("Cantidad de días")]
        public int CantidadDiasP
        {
            get { return cantidadDiasP; }
            set { cantidadDiasP = value; }
        }

        [DisplayName("Precio individual")]
        public double PrecioIndividual
        {
            get { return precioIndividual; }
            set { precioIndividual = value; }
        }

        [DisplayName("Precio para 2 personas")]
        public double PrecioDosP
        {
            get { return precioDosP; }
            set { precioDosP = value; }
        }

        [DisplayName("Precio para 3 personas")]
        public double PrecioTresP
        {
            get { return precioTresP; }
            set { precioTresP = value; }
        }

        [DisplayName("Usuario")]
        public Empleados Empleado
        {
            get { return empleado; }
            set { empleado = value; }
        }

        [DisplayName("Vuelo de Ida")]
        public Vuelos VueloIda
        {
            get { return vueloIda; }
            set { vueloIda = value; }
        }

        [DisplayName("Vuelo de Vuelta")]
        public Vuelos VueloVuelta
        {
            get { return vueloVuelta; }
            set { vueloVuelta = value; }
        }

        public Estados Estado
        {
            get { return estado; }
            set { estado = value; }
        }

        [DisplayName("Hospedajes")]
        public List<Incluyen> IncluyenHospedajes
        {
            get { return incluyenHospedajes; }
            set { incluyenHospedajes = value; }
        }

        // constructor completo
        public PaquetesViajes(string pTitulo, string pDescripcion, int pCantidadDiasP, double pPrecioIndividual, double pPrecioDosP, double pPrecioTresP, 
            Empleados pEmpleado, Vuelos pVueloIda, Vuelos pVueloVuelta, Estados pEstado, List<Incluyen> pIncluyenHospedajes) 
        {            
            Titulo = pTitulo;
            Descripcion = pDescripcion;
            CantidadDiasP = pCantidadDiasP;
            PrecioIndividual = pPrecioIndividual;
            PrecioDosP = pPrecioDosP;
            PrecioTresP = pPrecioTresP;
            Empleado = pEmpleado;
            VueloIda = pVueloIda;
            VueloVuelta = pVueloVuelta;
            Estado = pEstado;
            IncluyenHospedajes = pIncluyenHospedajes;
        }

        // constructor por defecto
        public PaquetesViajes() { }

        // operación validar --> código defensivo
        public void Validar()
        {
            if (string.IsNullOrWhiteSpace(this.Titulo) || this.Titulo.Trim().Length > 25)
                throw new Exception("El título no debe estar vacío ni superar los 25 caracteres");
            if (string.IsNullOrWhiteSpace(this.Descripcion))
                throw new Exception("Debe ingresar la descripción");
            if (this.CantidadDiasP <= 0)
                throw new Exception("La cantidad de días debe ser mayor a 0");
            if (this.PrecioIndividual <= 0 || this.PrecioDosP <= 0 || this.PrecioTresP <= 0)
                throw new Exception("Todos los precios deben ser mayores a 0");
            if (this.PrecioDosP <= this.PrecioIndividual)
                throw new Exception("El precio para 2 personas debe ser mayor al individual");
            if (this.PrecioTresP <= this.PrecioDosP)
                throw new Exception("El precio para 3 personas debe ser mayor al de 2 personas");
            if (this.Empleado == null)
                throw new Exception("Ha ocurrido un error con el Usuario, cierre cesión, vuelva a conectarse e inténtelo nuevamente");
            if (this.VueloIda == null || this.VueloVuelta == null)
                throw new Exception("Debe seleccionar vuelo de ida y vuelta");            
            if (this.Estado == null)
                throw new Exception("Debes seleccionar el Estado");
            if (this.IncluyenHospedajes == null || this.IncluyenHospedajes.Count == 0)
                throw new Exception("Debe seleccionar al menos 1 hospedaje");

        }
    }
}
