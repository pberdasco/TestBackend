import { hash, compare } from 'bcrypt';

export default class Cripto {
    /**
     * Genera un hash unidireccional de la contraseña usando bcrypt.
     * No requiere clave externa porque el algoritmo:
     *  - Genera internamente un "salt" aleatorio y lo incluye en el hash final
     *  - Aplica un número configurable de rondas (cost factor)
     *  - Es un mecanismo unidireccional: no se puede revertir para obtener la clave original
     */
    static async encrypt (pass) {
        const passHash = await hash(pass, 8);
        return passHash;
    }

    /**
     * Verifica que una contraseña en texto plano coincida con el hash almacenado.
     * El salt se obtiene del propio hash.
     */
    static async verified (pass, passHash) {
        const isOk = await compare(pass, passHash);
        return isOk;
    }
}
