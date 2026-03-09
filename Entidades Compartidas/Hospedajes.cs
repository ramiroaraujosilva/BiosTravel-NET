using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using System.ComponentModel;

namespace Entidades_Compartidas
{
    public class Hospedajes
    {
        // atributos
        private string codigoInterno;
        private string nombre;
        private string calle;
        private string localidad;
        private double precioH;
        private string tipoH;
        private Estados estado;

        // propiedades
        public string CodigoInterno
        {
            get { return codigoInterno; }
            set { codigoInterno = value; }
        }

        public string Nombre
        {
            get { return nombre; }
            set { nombre = value; }
        }

        public string Calle
        {
            get { return calle; }
            set { calle = value; }
        }

        public string Localidad
        {
            get { return localidad; }
            set { localidad = value; }
        }

        [DisplayName("Precio")]
        public double PrecioH
        {
            get { return precioH; }
            set { precioH = value; }
        }

        [DisplayName("Tipo")]
        public string TipoH
        {
            get { return tipoH; }
            set { tipoH = value; }
        }

        public Estados Estado
        {
            get { return estado; }
            set { estado = value; }
        }

        // tipos validos
        public static List<string> TiposValidos()
        {
            return new List<string> { "Hotel STD", "Posada", "All Inclusive", };
        }

        // constructor completo
        public Hospedajes(string pCodigoInterno, string pNombre, string pCalle, string pLocalidad, double pPrecioH, string pTipoH, Estados pEstado)
        {
            CodigoInterno = pCodigoInterno;
            Nombre = pNombre;
            Calle = pCalle;
            Localidad = pLocalidad;
            PrecioH = pPrecioH;
            TipoH = pTipoH;
            Estado = pEstado;
        }

        //constructo por defecto
        public Hospedajes() { }

        // operación Validar --> código defensivo
        public void Validar()
        {
            if (string.IsNullOrWhiteSpace(this.CodigoInterno) || this.CodigoInterno.Trim().Length > 10 || this.CodigoInterno.Any(c => !char.IsLetter(c)))
                throw new Exception("El código debe tener entre 1 y 10 letras");
            if (string.IsNullOrWhiteSpace(this.Nombre) || this.Nombre.Trim().Length > 30)
                throw new Exception("El nombre no puede estar vacío, y no puede superar los 30 caracteres");
            if (string.IsNullOrWhiteSpace(this.Calle) || this.Calle.Trim().Length > 30)
                throw new Exception("El campo de la calle no puede estar vacía, y no puede superar los 30 caracteres");
            if (string.IsNullOrWhiteSpace(this.Localidad) || this.Localidad.Trim().Length > 30)
                throw new Exception("El campo de la localidad no puede estar vacía, y no puede superar los 30 caracteres");
            if (this.PrecioH <= 0)
                throw new Exception("El precio del hospedaje debe ser mayor a 0");
            if (!TiposValidos().Contains(this.TipoH))
                throw new Exception("El tipo de hospedaje no es válido. Opciones viables: Hotel STD, Posada o All Inclusive");
            if (this.Estado == null)
                throw new Exception("Debes seleccionar el Estado");
        }
    }
}
